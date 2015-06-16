_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'

Coconut = require '../Coconut'

class Sync extends Backbone.Model
  initialize: ->
    @set
      _id: "SyncLog"

  target: -> Coconut.config.cloud_url()

  last_send: =>
    return @get("last_send_result")

  was_last_send_successful: =>
    return false if @get("last_send_error") is true
    # even if last_send_error was false need to check log
    last_send_data = @last_send()
    return false unless last_send_data?
    return true if last_send_data.no_changes? and last_send_data.no_changes is true
    return (last_send_data.docs_read is last_send_data.docs_written) and last_send_data.doc_write_failures is 0

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


  checkForInternet: (options) =>
    @log "Checking for internet. (Is #{Coconut.config.cloud_url()} is reachable?) Please wait."
    $.ajax
      url: Coconut.config.cloud_url()
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
                  @log "Synchronizing #{result.rows.length} results. Please wait."
                  resultIDs = _.pluck result.rows, "id"

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
                    _.delay ->
                      document.location.reload()
                    , 5000


  replicateApplicationDocs: (options) =>
    @checkForInternet
      error: (error) -> options?.error?(error)
      success: =>
        @log "Getting list of application documents to replicate"
        # Updating design_doc, users & forms
        $.ajax
          url: "#{Coconut.config.cloud_url()}/_design/coconut/_view/docIDsForUpdating"
          dataType: "json"
          include_docs: false
          error: (a,b,error) =>
            options.error?(error)
          success: (result) =>
            doc_ids = _.pluck result.rows, "id"
            doc_ids = _(doc_ids).without "_design/coconut"
            @log "Updating #{doc_ids.length} docs <small>(users and forms: #{doc_ids.join(',')})</small>. Please wait."
            Coconut.database.replicate.from Coconut.config.cloud_url_with_credentials(),
              doc_ids: doc_ids
            .on 'change', (info) =>
              $("#content").html "
                <h2>
                  #{info.docs_written} written out of #{doc_ids.length} (#{parseInt(100*(info.docs_written/doc_ids.length))}%)
                </h2>
              "
            .on 'complete', (info) =>
              resultData = _(info).chain().map (value,property) ->
                "#{property}: #{value}" if property.match /^doc.*/

              .compact()
              .value()

              @log "Finished updating application documents: #{JSON.stringify resultData}"
              options.success?()
            .on 'error', (error) =>
              @log "Error while updating application documents: #{JSON.stringify error}"
              options.error?(error)

module.exports = Sync
