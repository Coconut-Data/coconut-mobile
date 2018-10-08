_ = require 'underscore'
global._ = _
$ = require 'jquery'
Backbone = require 'backbone'
Router = require '../Router'
global.JSZip = require 'jszip'
global.MemoryStream = require 'memorystream'
Dialog = require '../../js-libraries/modal-dialog'

class ManageView extends Backbone.View
  events:
    "click #updatePlugin": "updatePlugin"
    "click #cloudResults": "getCloudResults"
    "click #sendBackup": "sendBackup"
    "click #saveBackup": "saveBackup"

  updatePlugin: ->
    Coconut.syncPlugins().then =>
      alert("Plugin Updated. Click ok to refresh the page")
      document.location.reload()

  getCloudResults: ->
    Coconut.cloudDatabase.query "resultsByUserAndDate",
      startkey: [Coconut.currentUser.username(), moment().subtract(1,"month").format(Coconut.config.get "date_format")]
      endkey: [Coconut.currentUser.username(), moment().endOf("day").format(Coconut.config.get "date_format")]
    .catch (error) => console.error "ERROR, could not download list of results for user: #{Coconut.currentUser.username()}: #{JSON.stringify error}"
    .then (result) =>
      lastMonthIds = _.pluck result.rows, "id"

      downloadResults = (docIds) ->
        Coconut.debug "Downloading #{docIds.length} results"
        Coconut.database.replicate.from Coconut.cloudDatabase,
          doc_ids: docIds
        .on 'complete', (info) =>
          $("#log").html ""
          Dialog.showDialog
            title: "C o m p l e t e",
            text: "<div>It may take a few minutes before all results are shown, but you can capture new data while these results are loading.</div>"
            neutral:
              title: "Close"
        .on 'error', (error) =>
          console.log JSON.stringify error
        .on 'change', (info) =>
          $("#message").show().html "
            <h2>
              #{info.docs_written} written out of #{docIds.length} (#{parseInt(100*(info.docs_written/docIds.length))}%)
            </h2>
          "
      Dialog.showDialog
        title: 'Confirmation'
        text: "Do you want to get #{lastMonthIds.length} results from last month saved by #{Coconut.currentUser.username()}"
        negative:
          title: 'No'
        positive:
            title: 'Yes',
            onClick: (e) ->
              downloadResults(lastMonthIds)

  sendBackup: ->
    # destination server https is configure at the Express config
    destination = "#{Coconut.config.cloud_url_hostname()}:3000/backup"
    @dumpDatabase
      error: (error) -> console.error error
      success: (dumpedString) ->
        $.ajax
          url: destination
          type: 'post'
          data:
            destination: Coconut.config.cloud_url_with_credentials()
            value: dumpedString
          success: (result) ->
            Dialog.showDialog
              title: "S U C C E S S",
              text: "<div>Database backup sent to: #{destination} where it was loaded into #{Coconut.config.cloud_url()}<br/>Result from server: #{result}</div>"
              neutral:
                title: "Close"
          error: (error) ->
            console.error error
            Dialog.showDialog
              title: "<span class='errMsg'>E R R O R</span>",
              text: "<div>Error backing up database: </div><div>#{JSON.stringify error}</div>"
              neutral:
                title: "Close"

  saveBackup: ->
    @dumpDatabase
      error: (error) -> console.error error
      success: (dumpedString) ->
        $("#message").show().html "Database backup created, beginning download. File will be available in Downloads folder on mobile device."
        zip = new JSZip()
        zip.file "backup.pouchdb", dumpedString
        zip.generateAsync
          type:"blob"
          compression:"DEFLATE"
        .then (content) ->
          FileSaver.saveAs(content, "coconut.pouchdb.zip")
          Dialog.showDialog
            title: "S U C C E S S",
            text: "<div>Database backup saved.</div><div>File will be available in Downloads folder on mobile device.</div>"
            neutral:
              title: "Close"
          $("#message").hide()

  dumpDatabase: (options) =>
    dumpedString = ''
    stream = new MemoryStream()
    stream.on 'data', (chunk) ->
      dumpedString += chunk.toString()

    Coconut.database.dump stream,
      filter: (doc) -> doc.collection is "result"
    .then ->
      console.log dumpedString
      options.success(dumpedString)

  render: ->

    links = [
      "Update Plugin, sync, updatePlugin"
      "Get previously sent results from cloud, archive, cloudResults"
      "Send Backup, cloud-upload, sendBackup"
      "Save Backup, briefcase-download, saveBackup"
    ]

    @$el.html "
      <div id='manageCard' class='mdl-card mdl-shadow--8dp coconut-mdl-card'></div>
      <div id='message'></div>
    "

    @$("#manageCard").html( _(links).map (link) ->
      [text,icon,id] = link.split(/,\s*/)

      "
        <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect manageLink' id='#{id}' type='button'>
          <i class='buttonIcon mdi mdi-#{icon} mdi-24px'></i>
          #{text}
        </button>
      "
    .join(""))

module.exports = ManageView
