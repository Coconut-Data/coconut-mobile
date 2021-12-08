$ = require 'jquery'
_ = require 'underscore'
radix64 = require('radix-64')()
global.bases = require('bases')

Config = require './models/Config'
global.Router = require './Router'
global.Sync = require './models/Sync'
global.User = require './models/User'

Encryptor = require('simple-encryptor')
encryptedInstallPaths = require './encryptedInstallPaths'

window.PouchDB = require('pouchdb-core')
PouchDB
  .plugin(require 'pouchdb-adapter-idb')
  .plugin(require 'pouchdb-adapter-http')
  .plugin(require 'pouchdb-find')
  .plugin(require 'pouchdb-mapreduce')
  .plugin(require 'pouchdb-replication')
  .plugin(require 'pouchdb-upsert')

#if isCordovaApp
#  PouchDB.plugin(require "pouchdb-adapter-cordova-sqlite")
#  pouchDBOptions['adapter'] = 'cordova-sqlite'

require('pouchdb-all-dbs')(window.PouchDB)

replicationStream = require('pouchdb-replication-stream')
PouchDB.plugin(replicationStream.plugin)
PouchDB.adapter('writableStream', replicationStream.adapters.writableStream)

window.pouchDBOptions = {
  auto_compaction: true
}

if isCordovaApp
  pouchDBOptions['adapter'] = 'cordova-sqlite'
  
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

      # retrieve selective general application settings from cloud and merge with local settings
      cloudDB = new PouchDB(@config.cloud_url_with_credentials(), {ajax:{timeout: 50000}})
      cloudDB.get "coconut.config"
      .then (result) =>
        @config.set("mobile_background_sync", result.mobile_background_sync || false)
        @config.set("mobile_background_sync_freq", result.mobile_background_sync_freq || 5)
        @config.set("date_format", result.date_format || "YYYY-MM-DD HH:mm:ss")
      .catch (error) =>
        @config.set("mobile_background_sync", false)
        @config.set("mobile_background_sync_freq", 5)
        @config.set("date_format", "YYYY-MM-DD HH:mm:ss")

      @downloadEncryptionKey
        error: (error) ->
          options.error(error)
        success:  =>
          $("#status").html "Creating #{@databaseName} database"
          @database = new PouchDB("coconut-#{options.params["Application Name"]}", pouchDBOptions)
          @database.crypto(@encryptionKey, ignore: '_attachments') unless @encryptionKey is null
          @database.put
            "_id": "decryption check"
            "is the value of this clear text": "yes it is"
          .then =>
            $("#status").html "Downloading forms and other application documents"
            sync = new Sync
            sync.replicateApplicationDocs
              error: (error) ->
                console.error "Updating application docs failed: #{JSON.stringify error}"
                alert(error)
                options.error "Updating the application failed: #{JSON.stringify error}"
              success: =>
                @createDatabaseForEachUser()
                .then =>
                  @config.save()
                  .then ->
                    console.log "SAVED config"
                    options.success()
                  .catch (error) ->
                    options.error "Error saving local config file"
                .catch (error) =>
                  console.error error
                  options.error error
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
    console.log "Checking for available plugins"
    $("#status").html "Checking for available plugins"
    @cloudDB = @cloudDB or new PouchDB(@config.cloud_url_with_credentials(), {ajax:{timeout: 50000}})
    @cloudDB.allDocs
      include_docs:false
      startkey: "_design/plugin-#{@databaseName}"
      endkey: "_design/plugin-#{@databaseName}\ufff0" #https://wiki.apache.org/couchdb/View_collation
    .catch (error) ->
      console.error "Error while downloading list of plugin ids:"
      console.error error
    .then (result) =>
      pluginIds = _(result.rows).pluck "id"
      pluginDatabase = new PouchDB("coconut-#{@databaseName}-plugins", pouchDBOptions)
      console.log "Downloading #{@databaseName} plugins: #{pluginIds}"
      $("#status").html "Downloading #{@databaseName} plugins"
      @cloudDB.replicate.to pluginDatabase,
        doc_ids: pluginIds
        timeout: 60000
        batch_size: 20
      .on 'change', (result) =>
        $("#status").append "*"
      .on 'complete', (result) =>
        console.log "Completed replicating plugins: #{pluginIds.join(',')}"

        for pluginId in pluginIds
          pluginDoc = await pluginDatabase.get pluginId
          console.log pluginDoc
          if pluginDoc.source and pluginDoc.doc_ids
            await (new Promise (resolve) =>
              ###
              console.log pluginId
              console.log await pluginDatabase.info()
              console.log await pluginDoc.source
              console.log pluginDoc.doc_ids
              ###
              doc_ids = [pluginId].concat(pluginDoc.doc_ids)
              pluginDatabase.replicate.from pluginDoc.source,
                doc_ids: doc_ids
              .on 'complete', (info) =>
                console.log "Replicated #{doc_ids.join(',')} from #{pluginDoc.source}"
                console.log info
                resolve()
              .on 'error', (error) =>
                message = "Error while replicating plugin docs: #{doc_ids.join(',')} for #{pluginId}: #{JSON.stringify error}"
                console.error message
                console.error error
                alert(message)
                resolve()
              )

        options?.success?()
        Promise.resolve()
      .on 'error', (error) =>
        Sync.checkForQuotaErrorAndAlert(error)
        console.error "Error while replicating plugins:"
        console.error error
        @syncPluginAttempts = 0 unless @syncPluginAttempts
        if @syncPluginAttempts < 5
          @syncPluginAttempts += 1
          console.log "Attempting to sync plugins again"
          @syncPlugins(options)
        else
          throw "Failed to sync plugins after #{@syncPluginAttempts} attempts"

  startPlugins: () =>
      pluginDatabase = new PouchDB("coconut-#{@databaseName}-plugins", pouchDBOptions)
      pluginDatabase.allDocs
        startkey: "_design"
        endkey: "_design\uf000"
      .then (result) ->
        # If the database is empty just call success
        Promise.resolve() if result.rows.length is 0

        Promise.all(_(result.rows).map (row) =>
          plugin = row.id
          console.info "Starting plugin: #{plugin}"
          pluginDatabase.getAttachment plugin, "plugin-bundle.js"
          .then (blob) ->
            BlobUtil.blobToBinaryString(blob).then (script) ->
              try
                window.eval script
              catch error
                console.error "Error loading #{plugin}"
                console.error error
              console.info "#{plugin} started"
              Promise.resolve()
          .catch (error) ->
            console.log "Error while loading plugin-bundle.js for #{plugin}:"
            console.log error
        )


  hashKeyForPassword: (password) =>
    #salt = (new Config()).get('salt')
    # No point in reusing same salt and no simple way to store salt per user, since only have username/password
    # Could change when/if we switch to use _users database
    salt = ""
    hashKey = (crypto.pbkdf2Sync password, salt, 1000, 256/8, 'sha256').toString('base64')

  openDatabase: (options) =>
    @userDatabase = new PouchDB("coconut-#{@databaseName}-user.#{options.username}", pouchDBOptions)
    @userDatabase.crypto(@hashKeyForPassword(options.password), ignore: '_attachments')
    @userDatabase.get "decryption check"
    .catch (error) =>
      if error.message is "Unsupported state or unable to authenticate data"
        console.error error
        throw "failed decryption check"
      else
        console.error error

        if error.name is "OperationError"
          throw "Invalid password"

        console.error "The database for #{options.username} is missing the encryption key. If #{options.username} is a valid username, then you need to update your username database from the cloud (internet connection required)?"
        throw "invalid user"
    .then (result) =>
      if result["is the value of this clear text"] isnt "yes it is"
        throw "username database failed decryption check"
      else
        @userDatabase.get "encryption key"
        .catch (error) -> 
          console.error error
          throw "could not find encryption key: #{JSON.stringify error}"
        .then (result) =>
          @encryptionKey = result["key"]
          @database = new PouchDB("coconut-#{@databaseName}", pouchDBOptions)
          @database.crypto(@encryptionKey, ignore: '_attachments') unless @encryptionKey is null # null encryption key used to disable encryption
          @database.allDocs
            include_docs: true
            limit: 1
          .catch (error) =>
            console.error "Successfully opened user database, but main database did not decrypt. Did encryption key change? Database: #{@databaseName} was not unencrypted. Tried to use key: #{@encryptionKey}. Error:"
            console.error error
            @database = null
            throw "Successfully opened user database, but main database did not decrypt."
          .then =>
            console.log "Main database decrypted"
            @config = new Config()
            @config.fetch()
            .catch =>
              alert "Error fetching config file - you probably need to reinstall"
            .then =>
              @config.attributes.mobile_background_sync = false
              @cloudDB = @cloudDB or new PouchDB(@config.cloud_url_with_credentials(), {ajax:{timeout:50000}})
              @setupBackbonePouch()
              User.login
                username: options.username
                password: options.password
              .then =>
                @startPlugins().then =>
                  @getOrAssignInstanceId().then (instanceId) =>
                    @instanceId = instanceId
                    @router.startApp().then =>

                      global.JackfruitConfig = await @database.get("JackfruitConfig").catch (error) -> Promise.resolve(null)
                      @fixCompletePropertyInResults()
                      # Look for a global StartPlugins array and then run all of the functions in it
                      if StartPlugins?
                        console.log "Starting Plugins"
                        for startPluginFunction in StartPlugins
                          await startPluginFunction()
                      # Will return a promise
                      console.log "All plugins started"

  fixCompletePropertyInResults: => # Bug generated some bad data for a few weeks - can remove after a few days
    @database.query "results",
      include_docs: true
    .then (result) =>
      for row in result.rows
        if row.doc.complete is "true"
          @database.upsert row.id, (doc) =>
            doc.complete = true
            doc
    .catch (error) =>
      console.error error


  destroyApplicationDatabases: (options) =>
    PouchDB.allDbs()
    .catch (error) => 
      console error "Error with allDBs:"
      console.error error
    .then (dbs) =>
      dbsToDestroy = _(dbs).filter (dbName) ->
        dbName.match "^coconut-"+options.applicationName

      await Promise.all dbsToDestroy.map (db) =>
      #for db in dbsToDestroy
        #await (new PouchDB(db, pouchDBOptions)).destroy()
        (new PouchDB(db, pouchDBOptions)).destroy()
        .catch (error) =>
          console.error "Error destroying: #{db}"
          console.error error

      options.success?()
      Promise.resolve()

  promptToUpdate: (cloudDBDetails) =>
    @databaseName = document.location.hash.replace(/#/,'').replace(/\/.*/,"")
    if cloudDBDetails is null
      cloudDBDetails = prompt("Enter Cloud DB Details")
    alert "Beginning update. It may take a few minutes to complete"
    @cloudDB = new PouchDB(cloudDBDetails)
    @cloudDB.get("client encryption key").then (keyDoc) =>
      if keyDoc.disabled
        @encryptionKey = null
      else
        @encryptionKey = keyDoc.key
      @database = new PouchDB("coconut-#{@databaseName}", pouchDBOptions)
      console.log @encryptionKey

      @database.crypto(@encryptionKey, ignore: '_attachments') unless @encryptionKey is null

      console.log "Resetting last_change_sequence_users to force all users to be re-created"
      @database.get("_local/last_change_sequence_users").catch()
      .then (sequenceDoc) =>
        @database.remove(sequenceDoc)

        .finally =>
          (new Sync()).replicateApplicationDocs
            success: =>
              alert("Update complete, please login")
              document.location.reload()

  createDatabaseForEachUser: =>
    console.log "Updating users if they have changed"
    @database.allDocs
      include_docs: false
      startkey: "user"
      endkey: "user\ufff0" #https://wiki.apache.org/couchdb/View_collation
    .catch (error) ->
      console.error "Error while downloading user information: #{JSON.stringify error}"
    .then (result) =>
      Promise.resolve(_(result.rows).pluck("id"))
    .then (allUserIds) =>
      console.log "Users: #{allUserIds.join(",")}"
      @database.get "_local/last_change_sequence_users"
      .catch (error)  =>
        console.log "no recorded last_change_sequence_users"
        Promise.resolve
          _id: "_local/last_change_sequence_users"
          sequence: null
      .then (sequenceResult) =>
        @database.info()
        .then (currentDBInfo) =>
          console.log currentDBInfo
          console.log sequenceResult
          @database.changes
            since: sequenceResult.sequence or ""
            doc_ids: allUserIds
            include_docs: true
          .then (result) =>
            changedUsers = _(result.results).pluck "doc"
            changedUserNames = _(changedUsers).map (user) => user._id.replace(/user\./,"")
            console.log "Users requiring update: #{changedUserNames.join(", ")}"
            console.log changedUsers.length
            return Promise.resolve("No users needed an update") if changedUsers.length is 0

            $("#status").html "Updating #{changedUsers.length} users. " if changedUsers.length > 0
            $("#loginErrMsg").html "Updating #{changedUsers.length} users. " if changedUsers.length > 0
            indx = 0

            #for user in changedUsers
            #  await @createDatabaseForUser(user).then =>
            await Promise.all changedUsers.map (user) =>
              @createDatabaseForUser(user).then =>
                $("div#percent").html "( #{++indx} of #{changedUsers.length} )"
                Promise.resolve()



            sequenceResult.sequence = currentDBInfo.update_seq
            @database.put sequenceResult
            .then =>
              Promise.resolve("Updated: #{changedUserNames.join(',')}")

    .catch (error) => console.error error

  createDatabaseForUser: (user) =>
    console.log "Creating PouchDB: coconut-#{@databaseName}-#{user._id}"
    userDatabase = new PouchDB("coconut-#{@databaseName}-#{user._id}", pouchDBOptions)
    userDatabase.destroy()
    .catch (error) =>
      console.error "Error while creating database:coconut-#{@databaseName}-#{user._id}"
      console.error error
    .then =>
      userDatabase = new PouchDB("coconut-#{@databaseName}-#{user._id}", pouchDBOptions)
      console.log "Created coconut-#{@databaseName}-#{user._id} and encrypting with password: #{user.password}"
      userDatabase.crypto(user.password, ignore: '_attachments')
      userDatabase.bulkDocs [{
        "_id": "encryption key"
        "key": @encryptionKey
      },{
        "_id": "decryption check"
        "is the value of this clear text": "yes it is"
      }]

  downloadEncryptionKey: (options) =>
    @cloudDB = new PouchDB(@config.cloud_url_with_credentials(), {ajax:{timeout: 50000}})
    @cloudDB.get "client encryption key"
    .catch (error) =>
      console.error "Failed to get client encryption key from #{@config.cloud_url_with_credentials()}"
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

    .then (result) =>
      if result.disabled
        @encryptionKey = null
      else
        @encryptionKey = result.key
      options.success()
      Promise.resolve()

  setConfig: (options) =>
    @config = new Config
      cloud: options["Cloud URL"]
      cloud_database_name: options["Application Name"]
      cloud_credentials: "#{options["Cloud Username"]}:#{options["Cloud Password"]}"

  validateDatabase: =>
    if @database
      @database.get "decryption check"
      .then (result) ->
        if result["is the value of this clear text"] is "yes it is"
          Promise.resolve()
        else
          Promise.reject "Failed decryption check"
    else
      Promise.reject "Database doesn't exist"

  toggleSpinner: (status) =>
    if status
      $("#pls_wait").show()
    else
      $("#pls_wait").hide()

  checkForInternet: (options) =>
    cloudUrl = @cloudDB.name.replace(/\/\/.*@/,"//")
    console.log "Checking for internet to #{cloudUrl}. Please wait..."
    @cloudDB.info()
    .catch (error) =>

      # In case the remote password has changed, allow the user to update it
      local_mobile_config = await @database.get "_local/mobile.config"
      if error.error is "unauthorized" and local_mobile_config
        password = prompt("Enter the update password (contact your supervisor if you are not sure):")
        installName = switch @config.cloud_database_name()
          when "zanzibar" then "z"
          when "keep" then "k"
          else
            alert "Unknown database name"
            null

        encryptedData = encryptedInstallPaths[installName]?.data
        data = Encryptor(password+password+password).decrypt(encryptedData)
        cloud_credentials = 
          if data?[3]? and data[4]?
            "#{data[3]}:#{data[4]}"
          else
            prompt "Enter the new credentials"
        
        if cloud_credentials and cloud_credentials isnt ""
          local_mobile_config.cloud_credentials = cloud_credentials
          await @database.put(local_mobile_config)
          await @config.fetch()
          @checkForInternet(options)
        else
          console.log "No valid credentials for cloud server"
          options.error "No valid credentials for cloud server"

      else
        console.log "WARNING! #{cloudUrl} is not reachable."
        console.error error
        options.error("No Internet connection")
    .then =>
      console.log "#{cloudUrl} is reachable."
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

  getOrAssignInstanceId: =>
    @database.get "_local/instance_id"
    .then (doc) ->
      Promise.resolve(doc.value)
    .catch (error) =>
      @assignInstanceId()

  # Server/database managed incrementing number for each installation of the app
  assignInstanceId: =>
    highestExistingInstanceId = await @cloudDB.allDocs
      startkey: "instance-"
      endkey: "instance-\uf000"
    .then (result) =>
      highestInstanceId = 0
      for row in result.rows
        instanceId = parseInt(row.id.split("-").pop())
        if instanceId > highestInstanceId
          highestInstanceId = instanceId
      Promise.resolve(highestInstanceId)

    proposedNewId = highestExistingInstanceId + 1

    @cloudDB.put
      "_id": "instance-#{proposedNewId}"
      creationTimestamp: (new Date()).toISOString()
    .then =>
      @database.upsert '_local/instance_id', (doc) =>
        _id: '_local/instance_id'
        value: proposedNewId
      .catch (error) -> throw "Could not save _local/instance_id: #{proposedNewId} #{JSON.stringify error}"
      .then -> Promise.resolve(proposedNewId)
    .catch (error) => # Database will enforce uniqueness in case this ID exists
      if confirm "Error while creating instance ID: #{JSON.stringify error}\n Do you want to try again?"
        Promise.resolve @assignInstanceId()
      else
        throw "Error creating instance ID"
        console.error error




module.exports = Coconut
