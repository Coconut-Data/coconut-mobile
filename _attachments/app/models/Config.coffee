$           = require('jquery')
Backbone    = require('backbone')
Backbone.$  = $

class Config extends Backbone.Model
  initialize: ->
    @set
      _id: "_local/mobile.config"

  fetch: (options) =>
    Coconut.database.get "_local/mobile.config"
    .then (result) =>
      @set(result)
      Promise.resolve()

  title: -> @get("title") || "Coconut"

  save: =>
    Coconut.database.put @attributes

  # See app/config.js
  database_name: -> Coconut.databaseName
  cloud_database_name: => @get("cloud_database_name") || @database_name()

  cloud_url: ->
    "#{@httpOrHttps()}://#{@cloud_url_no_http()}/#{@cloud_database_name()}"

  cloud_url_with_credentials: ->
    "#{@httpOrHttps()}://#{@get "cloud_credentials"}@#{@cloud_url_no_http()}/#{@cloud_database_name()}"

  cloud_log_url_with_credentials: ->
    "#{@httpOrHttps()}://#{@get "cloud_credentials"}@#{@cloud_url_no_http()}/#{@cloud_database_name()}-log"

  cloud_url_no_http: => @get("cloud").replace(/^https{0,1}:\/\//,"")

  httpOrHttps: =>
    if @get("cloud").match(/localhost/) or @get("cloud").match(/192.168/)
      "http"
    else
      # forcing this to https otherwise when getting encryption key, it will use http instead of https during a https connection
      # TODO - can be refactored to avoid using http
      "https"

  cloud_url_hostname: => "#{@httpOrHttps()}://#{@cloud_url_no_http()}"

module.exports =  Config
