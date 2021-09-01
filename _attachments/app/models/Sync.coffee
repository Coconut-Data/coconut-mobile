_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
Dialog = require '../../js-libraries/modal-dialog'

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
    if Coconut.config.get('mobile_background_sync')
      Coconut.checkForInternet
        error: (error) -> console.log("No internet connection. BackgroundSync skipped.")
        success: =>
          @lastSuccessfulSync = moment("2000-01-01") unless @lastSuccessfulSync? # TODO save this in PouchDB or use existing one
          console.log "backgroundSync called at #{moment().toString()} lastSuccessfulSync was #{@lastSuccessfulSync.toString()}}"
          minimumMinutesBetweenSync = @setMinMinsBetweenSync()
          Coconut.headerView.toggleSyncIcon(true)
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
          Coconut.headerView.toggleSyncIcon(false)
          Coconut.syncView.update()


    # Check if there are new results
    # Send results if new results and timeout

  sendToCloud: (options) =>
    @fetch
      error: (error) =>
        @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
        options?.error?(error)
      success: =>
        Coconut.checkForInternet
          error: (error) =>
            @save
              last_send_error: true
            options?.error?(error)
            Coconut.noInternet()
          success: =>
            @log "Creating list of all results on the mobile device. Please wait."
            await Coconut.database.query "results", {},
              (error,result) =>
                if error
                  console.log "Could not retrieve list of results: #{JSON.stringify(error)}"
                  alert "Could not retrieve list of results: #{JSON.stringify(error)}"
                  options?.error?(error)
                  @save
                    last_send_error: true
                else
                  @resultIDs = if options.completeResultsOnly? and options.completeResultsOnly is true
                    _.chain(result.rows)
                    .filter (row) ->
                      row.key[1] is true # Only get complete results
                    .pluck("id").value()
                  else
                    _.pluck result.rows, "id"

                  $("#status").append "<br/>Synchronizing #{@resultIDs.length} results. Please wait."

                  Coconut.database.replicate.to Coconut.cloudDB,
                    doc_ids: @resultIDs
                    timeout: 60000
                    batch_size: 20
                  .on 'complete', (info) =>
                    @log "Success! Send data finished: created, updated or deleted #{info.docs_written} results on the server."
                    @save
                      last_send_result: result
                      last_send_error: false
                      last_send_time: new Date().getTime()
                    Promise.resolve()
                  .on 'error', (error) ->
                    $("#status").append "<br/>ERROR: While replicating results to server: #{JSON.stringify error}"
                    console.error error
                    options.error(error)

            ###
            # EXAMPLE ACTION ON SYNC
            millisecondsSinceBeginningOf2021 = moment().format('x') - moment("2021-01-01").format('x')
            millisecondsEncodedAsBase32 = bases.toBase32(millisecondsSinceBeginningOf2021)

            Coconut.database.put
              _id: "syncAction_#{Coconut.instanceId}_#{millisecondsEncodedAsBase32}"
              action: "await fetch('https://lapq907iz0.execute-api.us-east-1.amazonaws.com/default/corsProxy?url=https://example.com')"
              description: "Test Action"
            ###

            @log "Checking for outstanding actions on sync"
            await Coconut.database.allDocs
              startkey: "syncAction_"
              endkey: "syncAction_\uf000"
              include_docs: true
            .then (result) =>
              for row in result.rows
                unless row.doc.complete
                  @log "Sync action: #{row.doc.description or row.doc.action}"
                  console.log "Found sync action:"
                  console.log row.doc.action
                  # Format for coffeescript spacing
                  action = row.doc.action.replace(/\n/g,"\n      ")
        
                  codeToEvalAsPromiseReturningFunction = """
->
  new Promise (response) ->
    response(
      #{action}
    )
"""

                  try
                    evaldFunction = await CoffeeScript.eval(codeToEvalAsPromiseReturningFunction, {bare:true})

                    # Now execute the function
                    await evaldFunction()
                    .then (result) =>
                      console.log "RESULT:"
                      console.log result
                      row.doc.complete = true
                      row.doc.result = result
                      row.doc.completeTime = moment().format("YYYY-MM-DD HH:mm:ss")
                    .catch (error) =>
                      console.error "Error on this sync action:"
                      console.error codeToEvalAsPromiseReturningFunction
                      console.error "Here's the error"
                      console.error error

                      row.doc.complete = false
                      row.doc.error or= []
                      row.doc.error.push error
                    await Coconut.database.put row.doc

                  catch error
                    console.error error
              Promise.resolve()
            Promise.resolve()
            options?.success?()

  saveResultRevsFromCloudDB: =>
    resultIDs = @resultIDs or await Coconut.database.allDocs({startkey:"result", endkey:"result\uf000"})
    .then (result) => _(result.rows).pluck "id"

    resultsOnServer = await Coconut.cloudDB.allDocs
      keys: resultIDs
    .then (result) => Promise.resolve result.rows

    resultsWithServerRevs = {}
    for result in resultsOnServer
      console.log result
      resultsWithServerRevs[result.id] = result.value?.rev

    @log "Saved version on server for #{resultsOnServer.length} results."
    await Coconut.database.upsert "resultsWithServerRevs", (doc) =>
      doc.serverRevs = resultsWithServerRevs
      doc



  log: (message) =>
    Coconut.debug message

  getFromCloud: (options) =>
    @fetch
      error: (error) =>
        @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
        options?.error?(error)
      success: =>
        Coconut.checkForInternet
          error: (error) ->
            @save
              last_send_error: true
            options?.error?(error)
            Coconut.noInternet()
          success: =>
            @fetch
              success: =>
                @replicateApplicationDocs
                  error: (error) =>
                    $.couch.logout()
                    console.error error
                    @save
                      last_get_success: false
                    options?.error?(error)
                  success: =>
                    @save
                      last_get_success: true
                      last_get_time: new Date().getTime()
                    options?.success?()
                    Promise.resolve()


  replicateApplicationDocs: (options) =>
    Coconut.checkForInternet
      error: (error) ->
        options?.error?(error)
        Coconut.noInternet()
      success: =>
        @log "Getting list of application documents to replicate"
        # Updating design_doc, users & forms
        Coconut.cloudDB.query "docIDsForUpdating",
          include_docs: false
        .then (result) =>
          doc_ids = _(result.rows).chain().pluck("id").without("_design/coconut").uniq().value()
          @log "Updating #{doc_ids.length} docs <small>(users and forms: #{doc_ids.join(', ')})</small>. Please wait."
          Coconut.database.replicate.from Coconut.cloudDB,
            doc_ids: doc_ids
            timeout: 60000
          .on 'error', (error) =>
            Sync.checkForQuotaErrorAndAlert(error)
            console.error error
          .on 'complete', (info) =>
            console.log info
          .on 'complete', (info) =>
            console.log info
            Coconut.createDatabaseForEachUser()
            .then =>
              console.log "Application docs and user refresh complete"
              Coconut.syncPlugins
                success: -> 
                  options?.success?()
                  Promise.resolve()
                error: -> options?.error?()
        .catch (error) =>
          @log "Error while updating application documents: #{JSON.stringify error}"
          @syncAttempts = 1 unless @syncAttempts
          if @syncAttempts < 5
            @syncAttempts += 1
            console.log "Attempting to sync plugins again (#{@syncAttempts}/5"
            @replicateApplicationDocs(options)
          else
            throw "Failed to sync plugins after #{@syncAttempts} attempts"
            options.error?(error)


  setMinMinsBetweenSync: =>
    minimumMinutesBetweenSync = if Coconut.config.get('mobile_background_sync_freq') > 1440 then 1440 else Coconut.config.get('mobile_background_sync_freq')
    minimumMinutesBetweenSync = if minimumMinutesBetweenSync < 5 then 5 else minimumMinutesBetweenSync
    if Coconut.config.get('mobile_background_sync')
      _.delay @backgroundSync, minimumMinutesBetweenSync*60*1000
    return minimumMinutesBetweenSync

Sync.checkForQuotaErrorAndAlert = (error) =>
  if error.reason is "QuotaExceededError"
    alert "You are out of disk space. Please free up disk space and try again. You may need to restart the device if the error persists after freeing up disk space. #{error.details or ""}"
    return "You are out of disk space. Please free up disk space and try again. You may need to restart the device if the error persists after freeing up disk space."
  return null
    

module.exports = Sync
