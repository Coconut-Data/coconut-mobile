$ = require 'jquery'

Config = require './models/Config'
Router = require './Router'
global.Sync = require './models/Sync'
User = require './models/User'

window.PouchDB = require 'pouchdb'
require 'crypto-pouch'

Backbone = require 'backbone'
Backbone.$  = $
BackbonePouch = require 'backbone-pouch'
BlobUtil = require 'blob-util'

class Coconut
  debug: (string) ->
    console.log string
    $("#log").append string + "<br/>"

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
    @databaseName = options["Application Name"]

    $("#status").html "Checking to see if #{@databaseName} already exists"

    PouchDB.allDbs().then (dbs) =>
      if _(dbs).includes "coconut-#{@databaseName}"
        options.actionIfDatabaseExists()
      else
        try
          @setConfig(options)
          @downloadEncryptionKey
            error: (error) ->
              options.error(error)
            success:  =>
              console.log "DDOO"
              $("#status").html "Creating #{@databaseName} database"
              new PouchDB("coconut-#{options["Application Name"]}")
              @database = new PouchDB("coconut-#{options["Application Name"]}")
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
                          @syncPlugins
                            success: =>
                              options.success()
                            error: =>
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
    userDatabase.crypto(options.password).then =>
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
                        success: ->
                          # Look for a global StartPlugins array and then run all of the functions in it
                          if StartPlugins?
                            _(StartPlugins).each (startPlugin) -> startPlugin()
                          User.login
                            username: options.username
                            error: ->
                              options.error()
                            success: ->
                              options.success()

                else
                  console.log "Succesfully opened user database, but main database did not decrypt. Did encryption key change? Database: #{@databaseName} was not unencrypted. Tried to use key: #{@encryptionKey}. Encryption check result was: #{JSON.stringify result}"
                  @database = null
                  options.error()

  destroyApplicationDatabases: (options) =>
    PouchDB.allDbs().then (dbs) =>
      dbsToDestroy = _(dbs).filter (dbName) ->
        dbName.match "^coconut-"+options.applicationName
      
      finished = _.after dbsToDestroy.length, ->
        options.success?()

      _(dbsToDestroy).each (db) ->
        console.log "Deleting #{db}"
        (new PouchDB(db)).destroy().then (response) ->
          console.log "#{db} Destroyed"
          console.log response
          finished()

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

      $("#status").html "Setting up #{result.rows.length} users. "

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
              $("#status").append "*"
              callSuccessWhenFinished()

  downloadEncryptionKey: (options) =>
    @cloudDB = new PouchDB(@config.cloud_url_with_credentials())
    @cloudDB.get "client encryption key"
    .catch (error) =>
      console.error "Failed to get client encryption key from #{cloudDB}"
      console.error error
      options.error "Failed to get client encyrption key from #{@config.cloud_url_with_credentials()}"
    .then (result) =>
      @encryptionKey = result.key
      options.success()

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
      options.error()

module.exports = Coconut
