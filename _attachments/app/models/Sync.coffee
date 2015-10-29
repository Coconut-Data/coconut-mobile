_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'

class Sync extends Backbone.Model
  initialize: ->
    @set
      _id: "SyncLog"

  target: -> Coconut.config.cloud_url()

  last_send: =>
    return @get("last_send_result")

  was_last_send_successful: =>
    return not @get("last_send_error") or false

  last_send_time: =>
    result = @get("last_send_time")
    if result
      return moment(@get("last_send_time")).fromNow()
    else
      return "never"

  was_last_get_successful: =>
    return @get "last_get_success"

  last_get_time: =>
    result = @get("last_get_time")
    if result
      return moment(@get("last_get_time")).fromNow()
    else
      return "never"

  backgroundSync: =>
    @lastSuccessfulSync = moment("2000-01-01") unless @lastSuccessfulSync? # TODO save this in PouchDB or use existing one
    console.log "backgroundSync called at #{moment().toString()} lastSuccessfulSync was #{@lastSuccessfulSync.toString()}}"
    minimumMinutesBetweenSync = 15

    _.delay @backgroundSync, minimumMinutesBetweenSync*60*1000

    Coconut.questions.each (question) =>
      Coconut.database.query "results",
        startkey: [question.id,true,@lastSuccessfulSync.format(Coconut.config.get("date_format"))]
        endkey: [question.id,true,{}]
      .then (result) =>
        if result.rows.length > 0 and moment().diff(@lastSuccessfulSync,'minutes') > minimumMinutesBetweenSync
          console.log "Initiating background sync"
          $("div#log").hide()
          @sendToCloud
            completeResultsOnly: true
            error: (error) ->
              console.log "Error: #{JSON.stringify error}"
              $("div#log").html("")
              $("div#log").show()
            success: =>
              @lastSuccessfulSync = moment()
              $("div#log").html("")
              $("div#log").show()
        else
          console.log "No new results for #{question.id} so not syncing"
  

    # Check if there are new results
    # Send results if new results and timeout

  checkForInternet: (options) =>
    @log "Checking for internet. (Is #{Coconut.config.cloud_url()} is reachable?) Please wait."
    $.ajax
      url: Coconut.config.cloud_url_with_credentials()
      xhrFields: {withCredentials: true}
      error: (error) =>
        @log "ERROR! #{Coconut.config.cloud_url()} is not reachable. Do you have enough airtime? Are you on WIFI?  Either the internet is not working or the site is down: #{JSON.stringify(error)}"
        options.error()
        @save
          last_send_error: true
      success: =>
        @log "#{Coconut.config.cloud_url()} is reachable, so internet is available."
        options.success()

  sendToCloud: (options) =>
    @fetch
      error: (error) => @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
      success: =>
        @checkForInternet
          error: (error) -> options?.error?(error)
          success: =>
            @log "Creating list of all results on the tablet. Please wait."
            Coconut.database.query "results", {},
              (error,result) =>
                if error
                  @log "Could not retrieve list of results: #{JSON.stringify(error)}"
                  options.error()
                  @save
                    last_send_error: true
                else
                  resultIDs = if options.completeResultsOnly? and options.completeResultsOnly is true
                    _.chain(result.rows)
                    .filter (row) ->
                      row.key[1] is true # Only get complete results
                    .pluck("id").value()
                  else
                    _.pluck result.rows, "id"

                  @log "Synchronizing #{resultIDs.length} results. Please wait."

                  Coconut.database.replicate.to Coconut.config.cloud_url_with_credentials(),
                    doc_ids: resultIDs
                  .on 'complete', (info) =>
                    @log "Success! Send data finished: created, updated or deleted #{info.docs_written} results on the server."
                    @save
                      last_send_result: result
                      last_send_error: false
                      last_send_time: new Date().getTime()
                    options.success()
                  .on 'error', (error) ->
                    console.error error
                    options.error(error)


  log: (message) =>
    Coconut.debug message

  getFromCloud: (options) =>
    @fetch
      error: (error) => @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
      success: =>
        @checkForInternet
          error: (error) -> options?.error?(error)
          success: =>
            @fetch
              success: =>
                @replicateApplicationDocs
                  error: (error) =>
                    $.couch.logout()
                    @log "ERROR updating application: #{JSON.stringify(error)}"
                    @save
                      last_get_success: false
                    options?.error?(error)
                  success: =>
                    @save
                      last_get_success: true
                      last_get_time: new Date().getTime()
                    options?.success?()


  replicateApplicationDocs: (options) =>
    @checkForInternet
      error: (error) -> options?.error?(error)
      success: =>
        @log "Getting list of application documents to replicate"
        # Updating design_doc, users & forms
        $.ajax
          url: "#{Coconut.config.cloud_url_with_credentials()}/_design/docIDsForUpdating/_view/docIDsForUpdating"
          xhrFields: {withCredentials: true}
          dataType: "json"
          include_docs: false
          error: (a,b,error) =>
            options.error?(error)
          success: (result) =>
            doc_ids = _(result.rows).chain().pluck("id").without("_design/coconut").uniq().value()
            @log "Updating #{doc_ids.length} docs <small>(users and forms: #{doc_ids.join(', ')})</small>. Please wait."
            Coconut.database.replicate.from Coconut.config.cloud_url_with_credentials(),
              doc_ids: doc_ids
            .on 'change', (info) =>
              console.log info
            .on 'complete', (info) =>
              console.log "COMPLETE"
              options.success?()
            .on 'error', (error) =>
              @log "Error while updating application documents: #{JSON.stringify error}"
              options.error?(error)

module.exports = Sync
