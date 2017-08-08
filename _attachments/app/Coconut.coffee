$ = require 'jquery'

Config = require './models/Config'
global.Router = require './Router'
global.Sync = require './models/Sync'
User = require './models/User'

window.PouchDB = require 'pouchdb'
require 'crypto-pouch'
crypto = require('crypto')

Backbone = require 'backbone'
Backbone.$  = $
BackbonePouch = require 'backbone-pouch'
BlobUtil = require 'blob-util'
Dialog = require '../js-libraries/modal-dialog'

class Coconut
  debug: (string) ->
    console.log string
#    $("#log").append string + "<br/>"

  colors: {
    primary1: "rgb(63,81,181)"
    primary2: "rgb(48,63,159)"
    accent1: "rgb(230,33,90)"
    accent2: "rgb(194,24,91)"
  }

  ###
  Ask user to provide cloud database info
  Download all user documents
  Download encryption key
  Create encrypted pouchdb coconut-ProjectName-username with passwords as key
  Add one document holding shared encryption key
  Add document with something clear text to be used to validate that the database was successfully decrypted
  Create coconut-ProjectName encrypted with encryption key
  ###

  createDatabases: (options) =>
    @databaseName = options.params["Application Name"]
    try
      @setConfig(options.params)
      @downloadEncryptionKey
        error: (error) ->
          options.error(error)
        success:  =>
          $("#status").html "Creating #{@databaseName} database"
          new PouchDB("coconut-#{options.params["Application Name"]}")
          @database = new PouchDB("coconut-#{options.params["Application Name"]}")
          @database.crypto(@encryptionKey).then =>
            @database.put
              "_id": "decryption check"
              "is the value of this clear text": "yes it is"
            .then =>
              @createDatabaseForEachUser
                error: (error) ->
                  console.error error
                  options.error error
                success: =>
                  $("#status").html "Downloading forms and other application documents"
                  sync = new Sync
                  sync.replicateApplicationDocs
                    error: (error) ->
                      console.error "Updating application docs failed: #{JSON.stringify error}"
                      options.error "Updating the application failed: #{JSON.stringify error}"
                    success: =>
                      options.success()
    catch error
      console.error error
      console.error "Removing #{@databaseName} due to incomplete setup"
      @destroyApplicationDatabases
        applicationName: @databaseName

  setupBackbonePouch: ->
    Backbone.sync = BackbonePouch.sync
      db: @database
      fetch: 'query'
    Backbone.Model.prototype.idAttribute = '_id'

  syncPlugins: (options) =>
    $("#status").html "Checking for available plugins"
    @cloudDB = @cloudDB or new PouchDB(@config.cloud_url_with_credentials())
    @cloudDB.allDocs
      include_docs:false
      startkey: "_design/plugin-#{@databaseName}"
      endkey: "_design/plugin-#{@databaseName}\ufff0" #https://wiki.apache.org/couchdb/View_collation
    .then (result) =>
      pluginDatabase = new PouchDB("coconut-#{@databaseName}-plugins")
      pluginIds = _(result.rows).pluck "id"
      $("#status").html "Loading #{@databaseName} plugins: #{pluginIds}"
      @cloudDB.replicate.to pluginDatabase,
        doc_ids: pluginIds
      .on 'error', (error) ->
        console.error "Error while replicating plugins:"
        console.error error
      .on 'change', (result) =>
        $("#status").append "*"
      .on 'complete', (result) =>
        console.log "Completed replicating plugins: #{pluginIds.join(',')}"
        options?.success?()
    .catch (error) ->
      console.error "Error while downloading list of plugin ids:"
      console.error error

  startPlugins: (options) =>
    pluginDatabase = new PouchDB "coconut-#{@databaseName}-plugins"
    pluginDatabase.allDocs()
    .catch (error) -> console.error error
    .then (result) ->
      # If the database is empty just call success
      options?.success?() if result.rows.length is 0

      finished = _.after result.rows.length,  ->
        options?.success?()

      _(result.rows).chain().pluck("id").each (plugin) ->
        console.log "Starting plugin: #{plugin}"
        pluginDatabase.getAttachment plugin, "plugin-bundle.js"
        .then (blob) ->
          BlobUtil.blobToBinaryString(blob).then (script) ->
            try
              window.eval script
            catch error
              console.error "Error loading #{plugin}"
              console.error error
            finished()

  openDatabase: (options) =>
    userDatabase = new PouchDB "coconut-#{@databaseName}-user.#{options.username}"
    salt = (new Config()).get('salt')
    hashKey = (crypto.pbkdf2Sync options.password, salt, 1000, 256/8, 'sha256').toString('base64')
    userDatabase.crypto(hashKey).then =>
      userDatabase.get "decryption check"
      .catch (error) ->
        console.log "Error opening decryption check doc, probably invalid username"
        console.log error
        options.error()
      .then (result) =>
        @encryptionKey = result[""]
        if result["is the value of this clear text"] isnt "yes it is"
          console.log "Decryption check has wrong value, probably invalid password"
          options.error()
        else
          userDatabase.get "encryption key"
          .catch (error) -> console.error error
          .then (result) =>
            @encryptionKey = result["key"]
            @database = new PouchDB("coconut-#{@databaseName}")
            @database.crypto(@encryptionKey).then =>
              @database.get "decryption check"
              .catch (error) -> console.error error
              .then (result) =>
                if result["is the value of this clear text"] is "yes it is"
                  console.log "Project database opened and decrypted"
                  @setupBackbonePouch()
                  @startPlugins
                    error: (error) -> console.error error
                    success: =>
                      @router.startApp
                        success: =>
                          # Look for a global StartPlugins array and then run all of the functions in it
                          if StartPlugins?
                            _(StartPlugins).each (startPlugin) -> startPlugin()
                          User.login
                            username: options.username
                            error: ->
                              options.error()
                            success: =>
                              options.success()

                else
                  console.log "Successfully opened user database, but main database did not decrypt. Did encryption key change? Database: #{@databaseName} was not unencrypted. Tried to use key: #{@encryptionKey}. Encryption check result was: #{JSON.stringify result}"
                  @database = null
                  options.error()

  destroyApplicationDatabases: (options) =>
    PouchDB.allDbs().then (dbs) =>
      if (dbs.length > 0)
        dbsToDestroy = _(dbs).filter (dbName) ->
          dbName.match "^coconut-"+options.applicationName

        promises = []
        _(dbsToDestroy).each (db) ->
          console.log "Deleting #{db}"
          promise = (new PouchDB(db)).destroy().then (response) ->
             console.log "#{db} Destroyed"
           .catch (err) ->
             console.error(err)
          promises.push(promise)
        Promise.all(promises).then ->
          options.success?()

  createDatabaseForEachUser: (options) =>
    @cloudDB.allDocs
      include_docs: true
      startkey: "user"
      endkey: "user\ufff0" #https://wiki.apache.org/couchdb/View_collation
    .catch (error) ->
      console.error "Error while downloading user information: #{JSON.stringify error}"
    .then (result) =>

      callSuccessWhenFinished = _.after result.rows.length, ->
        options.success()

      totalUsers = result.rows.length
      $("#status").html "Setting up #{totalUsers} users. "
      indx = 0
      _(result.rows).each (user) =>
        console.log "Creating PouchDB: coconut-#{@config.get("cloud_database_name")}-#{user.id}"
        userDatabase = new PouchDB "coconut-#{@config.get("cloud_database_name")}-#{user.id}"
        userDatabase.crypto(user.doc.password or "").then =>
          userDatabase.put
            "_id": "encryption key"
            "key": @encryptionKey
          .then =>
            userDatabase.put
              "_id": "decryption check"
              "is the value of this clear text": "yes it is"
            .then ->
              $("div#percent").html "( #{++indx} of #{totalUsers} )"
              callSuccessWhenFinished()

  downloadEncryptionKey: (options) =>
    @cloudDB = new PouchDB(@config.cloud_url_with_credentials())
    @cloudDB.get "client encryption key"
      .then (result) =>
        @encryptionKey = result.key
        options.success()
      .catch (error) =>
        console.error "Failed to get client encyrption key from #{@config.cloud_url_with_credentials()}"
        console.error error
        switch error.status
          when 0
            error_msg = "Cannot connect to the Cloud URL. Please check the URL."
          when 404
            error_msg = "Cannot find database. Make sure your Application Name is correct."
          when 400
            error_msg = error.reason
          when 401
            error_msg = "Cloud Username or Cloud Password is incorrect."
          else
            error_msg = error.message

        options.error "Failed to get client encryption key. <br /> #{error_msg}"

  setConfig: (options) =>
    @config = new Config
      cloud: options["Cloud URL"]
      cloud_database_name: options["Application Name"]
      cloud_credentials: "#{options["Cloud Username"]}:#{options["Cloud Password"]}"

  isValidDatabase: (options) =>
    if @database
      @database.get "decryption check"
      .catch (error) ->
        options.error(error)
      .then (result) ->
        if result["is the value of this clear text"] is "yes it is"
          options.success()
    else
      User.logout()
      options.error()

  toggleSpinner: (status) =>
    if status
      $("#pls_wait").show()
    else
      $("#pls_wait").hide()

  checkForInternet: (options) =>
    cloudUrl = @config.cloud_url_no_http()
    console.log "Checking for internet to #{cloudUrl}. Please wait..."
    $.ajax
      url: @config.cloud_url_with_credentials()
      xhrFields: {withCredentials: true}
      error: (error) =>
        console.log "WARNING! #{cloudUrl} is not reachable. Error encountered:  #{JSON.stringify(error)}"
        options.error("No Internet connection")
      success: =>
          console.log "#{cloudUrl} is reachable, so internet is available."
          options.success()

  noInternet: =>
    Dialog.showDialog
      title: "No Internet Connection",
      text: "#{@config.cloud_url_no_http()} is not reachable. Please ensure that you have internet connection before retrying."
      neutral:
        title: "Close",
        onClick: (e) ->
          document.location.reload()

  showNotification: (msg) =>
    notify = document.querySelector('.mdl-js-snackbar')
    notify.MaterialSnackbar.showSnackbar(
      message: msg
    )


module.exports = Coconut
