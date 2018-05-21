$ = require 'jquery'
_ = require 'underscore'
radix64 = require('radix-64')()

Config = require './models/Config'
global.Router = require './Router'
global.Sync = require './models/Sync'
global.User = require './models/User'

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
          @database = new PouchDB("coconut-#{options.params["Application Name"]}")
          @database.crypto(@encryptionKey).then =>
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
      pluginDatabase = new PouchDB("coconut-#{@databaseName}-plugins")
      pluginIds = _(result.rows).pluck "id"
      $("#status").html "Loading #{@databaseName} plugins"
      @cloudDB.replicate.to pluginDatabase,
        doc_ids: pluginIds
        timeout: 60000
        batch_size: 20
      .on 'change', (result) =>
        $("#status").append "*"
      .on 'complete', (result) =>
        console.log "Completed replicating plugins: #{pluginIds.join(',')}"
        options?.success?()
      .on 'error', (error) =>
        console.error "Error while replicating plugins:"
        console.error error
        @syncPluginAttempts = 0 unless @syncPluginAttempts
        if @syncPluginAttempts < 5
          @syncPluginAttempts += 1
          console.log "Attempting to sync plugins again"
          @syncPlugins(options)
        else
          throw "Failed to sync plugins after #{@syncPluginAttempts} attempts"

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

  hashKeyForPassword: (password) =>
    #salt = (new Config()).get('salt')
    # No point in reusing same salt and no simple way to store salt per user, since only have username/password
    # Could change when/if we switch to use _users database
    salt = ""
    hashKey = (crypto.pbkdf2Sync password, salt, 1000, 256/8, 'sha256').toString('base64')

  openDatabase: (options) =>
    userDatabase = new PouchDB "coconut-#{@databaseName}-user.#{options.username}"
    userDatabase.crypto(@hashKeyForPassword(options.password)).then =>
      userDatabase.get "decryption check"
      .catch (error) =>
        if error.reason is "missing"
          alert "The database for #{options.username} is missing the encryption key, page will refresh. You may need to reinstall if #{options.username} is a valid user."
          document.location.reload()
          ###
          @setConfig
            "Cloud URL": "http://localhost:5984"
            "Application Name": "keep"
            "Cloud Username": "admin"
            "Cloud Password": "password"
          @downloadEncryptionKey()
          .then =>
            @createDatabaseForUser
              id: "user.#{options.username}"
              doc:
                password: hashKey
          .then =>
            _.delay =>
              console.log "Trying to login again."
              @openDatabase(options)
            , 1000
          ###
        else
        
        console.log error
        userDatabase.info().then (info) ->
          #alert "Error opening decryption check doc, probably invalid username. username: #{options.username} password:#{options.password}, #{JSON.stringify error}, DB INFO: #{JSON.stringify info}"
          if info.doc_count is 0
            console.log "Error opening decryption check doc, username does not exist"
          else
            console.log "Error opening decryption check doc, password did not successfully decrypt the database"
          return options.error()
      .then (result) =>
        @encryptionKey = result[""]
        if result["is the value of this clear text"] isnt "yes it is"
          #alert "Decryption check has wrong value, probably invalid password: #{JSON.stringify result}"
          console.log "Decryption check has wrong value, probably invalid password: username: #{options.username} password:#{options.password}"

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
                  console.log "Login credentials successful, project database opened and decrypted"

                  @config = new Config()
                  @config.fetch
                    error: ->
                      Coconut.debug "Error loading config"
                    success: =>
                      # temporarily forcing to false for all preinstalled app
                      @config.attributes.mobile_background_sync = false
                      @cloudDB = @cloudDB or new PouchDB(@config.cloud_url_with_credentials(), {ajax:{timeout:50000}})
                      @setupBackbonePouch()
                      @startPlugins
                        error: (error) -> console.error error
                        success: =>

                          @getOrAssignInstanceId().then (instanceId) =>
                            @instanceId = instanceId

                            @router.startApp
                              success: =>
                                # Look for a global StartPlugins array and then run all of the functions in it
                                if StartPlugins?
                                  _(StartPlugins).each (startPlugin) -> startPlugin()
                                User.login
                                  username: options.username
                                  password: options.password
                                  error: (error) ->
                                    console.log error
                                    options.error(error)
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

        Promise.all(dbsToDestroy.map (db) ->
          (new PouchDB(db)).destroy()
        )
        .then ->
          options.success?()
          Promise.resolve()

  createDatabaseForEachUser: =>
    @database.allDocs
      include_docs: false
      startkey: "user"
      endkey: "user\ufff0" #https://wiki.apache.org/couchdb/View_collation
    .catch (error) ->
      console.error "Error while downloading user information: #{JSON.stringify error}"
    .then (result) =>
      Promise.resolve(_(result.rows).pluck("id"))
    .then (allUserIds) =>
      @database.get "_local/last_change_sequence_users"
      .catch (error)  =>
        Promise.resolve
          _id: "_local/last_change_sequence_users"
          sequence: null
      .then (sequenceResult) =>
        @database.info()
        .then (currentDBInfo) =>
          console.log currentDBInfo

          @database.changes
            since: sequenceResult.sequence
            doc_ids: allUserIds
            include_docs: true
          .then (result) =>
            changedUsers = _(result.results).pluck "doc"

            $("#status").html "Updating #{changedUsers.length} users. " if changedUsers.length > 0
            indx = 0

            Promise.all( changedUsers.map (user) =>
              @createDatabaseForUser(user).then =>
                $("div#percent").html "( #{++indx} of #{changedUsers.length} )"
                Promise.resolve()
            ).catch (error) -> console.error error

            sequenceResult.sequence = currentDBInfo.update_seq
            @database.put sequenceResult
    .catch (error) => console.error error

  createDatabaseForUser: (user) =>
    console.log "Creating PouchDB: coconut-#{@config.get("cloud_database_name")}-#{user._id}"
    userDatabase = new PouchDB "coconut-#{@config.get("cloud_database_name")}-#{user._id}"
    userDatabase.destroy()
    .then =>
      userDatabase = new PouchDB "coconut-#{@config.get("cloud_database_name")}-#{user._id}"
      userDatabase.crypto(user.password or "")
      .then =>
        userDatabase.put
          "_id": "encryption key"
          "key": @encryptionKey
      .then =>
        console.log "Created coconut-#{@config.get("cloud_database_name")}-#{user._id}"
        userDatabase.put
          "_id": "decryption check"
          "is the value of this clear text": "yes it is"

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
      @encryptionKey = result.key
      options.success()
      Promise.resolve()

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
      #User.logout()  # not sure why this was here, but it broken autologin after refresh
      options.error()

  toggleSpinner: (status) =>
    if status
      $("#pls_wait").show()
    else
      $("#pls_wait").hide()

  checkForInternet: (options) =>
    cloudUrl = @config.cloud_url_no_http()
    console.log "Checking for internet to #{cloudUrl}. Please wait..."
    @cloudDB.info().then =>
      console.log "#{cloudUrl} is reachable."
      options.success()
    .catch (error) =>
      console.log "WARNING! #{cloudUrl} is not reachable. Error encountered:  #{JSON.stringify(error)}"
      options.error("No Internet connection")

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

  # format: [unix-timestamp-radix64 encoded]
  assignInstanceId: =>

    unixMillisecondTimestampRadix64Encoded = -> radix64.encodeInt(moment().format('x'))

    @cloudDB = @cloudDB or new PouchDB(@config.cloud_url_with_credentials(), {ajax:{timeout:50000}})
    @cloudDB.get("assigned_instance_ids")
    .then (assignedInstanceIds) =>
      # Get the last one from the array
      lastAssignedInstanceId = assignedInstanceIds.ids[assignedInstanceIds.ids.length-1]
      lastAssignedInstanceIdIndex = parseInt(lastAssignedInstanceId.split(/ /)[0])
      assignedInstanceIds.ids.push unixMillisecondTimestampRadix64Encoded()
      Promise.resolve(assignedInstanceIds)
    .catch (error) ->
      console.log error
      # If it doesn't exist, this must be the first one, so create the doc
      if error.status is 404
        Promise.resolve
          _id: "assigned_instance_ids"
          ids: [unixMillisecondTimestampRadix64Encoded()]
      else
        throw "Error finding existing instance ids in cloud: #{JSON.stringify error}"
    .then (assignedInstanceIds) =>
      @cloudDB.put assignedInstanceIds
      .then =>
        assignedId = assignedInstanceIds.ids.pop()
        @database.put
          _id: '_local/instance_id'
          value: assignedId
        .catch (error) -> throw "Could not save _local/instance_id: #{JSON.stringify error}"
        .then -> Promise.resolve(assignedId)
      .catch (error) -> throw "Could not save new instance id to cloud: #{JSON.stringify error}"


module.exports = Coconut
