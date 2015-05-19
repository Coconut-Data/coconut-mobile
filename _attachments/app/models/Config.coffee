class Config extends Backbone.Model
  initialize: ->
    @set
      _id: "coconut.config"

  fetch: (options) =>
    database.get "coconut.config",
      (error,result) =>
        @set(result)
        database.get "coconut.config.local",
          (error,result) =>
            Coconut.config.local = new Backbone.Model()
            Coconut.config.local.set(result)
            options.success?()

  title: -> @get("title") || "Coconut"

  # See app/config.js
  database_name: -> database._db_name
  cloud_database_name: => @get("cloud_database_name") || @database_name()

  cloud_url: ->
    "http://#{@cloud_url_no_http()}/#{@cloud_database_name()}"

  cloud_url_with_credentials: ->
    "http://#{@get "cloud_credentials"}@#{@cloud_url_no_http()}/#{@cloud_database_name()}"

  cloud_log_url_with_credentials: ->
    "http://#{@get "cloud_credentials"}@#{@cloud_url_no_http()}/#{@cloud_database_name()}-log"

  cloud_url_no_http: => @get("cloud").replace(/http:\/\//,"")
