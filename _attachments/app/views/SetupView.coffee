$ = require 'jquery'
s = require 'underscore.string'

Backbone = require 'backbone'
Backbone.$  = $

class SetupView extends Backbone.View

  fields: [
    "Cloud URL"
    "Application Name"
    "Cloud Username"
    "Cloud Password"
  ]

  el: '#content'

  render: =>
    @$el.html "
      <h1>Install Coconut Project</h1>
      <div id='message'></div>
      <div id='form'
        Enter the setup details below:<br/>
      </div>
    "
    _(@fields).map (field) =>
      @$el.find("#form").append "#{field}<input style='display:block' id='#{s.dasherize(field)}'/>"

    @$el.find("#form").append "
      <button id='install' type='button'>Install</button>
    "
    
  events:
    "click #install": "install"
    "click #destroy": "destroy"

  prefill: (options) ->
    _(options).each (value , key) ->
      $("##{s.dasherize(key)}").val(value)

  destroy: =>
    applicationName = $("#"+s.dasherize("Application Name")).val()
    @$el.append "
      <div id='spinner'>
        <center>
          <h2>Removing  #{applicationName}</h2>
          <h3 id='status'></h3>
          <div style='height:200px;width:200px' class='mdl-spinner mdl-js-spinner is-active'></div>
        </center>
      </div>
    "
    componentHandler.upgradeDom()
    Coconut.destroyApplicationDatabases
      applicationName: applicationName
      success: =>
        # TODO make a fading out message
        $("#content").html "<h1>#{applicationName} Removed</h1>"
        $("#content h1").fadeOut 1000
        _.delay ->
          document.location.reload()
        , 1000
  
  install: ->
    applicationName = $("#"+s.dasherize("Application Name")).val()

    options =
      error: (error) ->
        $("#message").html "
        Error installing #{applicationName}:<br/> #{error}
          <br/><br/>
        "

      success: =>
        @$el.html "<h1>#{applicationName} Installed</h1>"
        @$el.find("h1").fadeOut 1000
        _.delay ->
          Coconut.router.navigate applicationName, trigger: true
        , 1000

      actionIfDatabaseExists: =>
        @$el.find("#form").show()
        @$el.find("#spinner").remove()
        $("#message").html "
          Application #{applicationName} has already been installed.<br/>
          You can update the fields below or delete all data for #{applicationName}.<br/>
          <button id='destroy'>Delete #{applicationName} </button>
          <br/><br/>
        "
        
    _(@fields).each (field) ->
      options[field] = $("##{s.dasherize(field)}").val()

    @$el.find("#form").hide()
    @$el.append "
      <div id='spinner'>
        <center>
          <h2>Installing #{applicationName}</h2>
          <h3 id='status'></h3>
          <div style='height:200px;width:200px' class='mdl-spinner mdl-js-spinner is-active'></div>
        </center>
      </div>
    "
    componentHandler.upgradeDom()
    $("#log").html ""
    $("#log").hide()

    Coconut.createDatabases options

module.exports = SetupView
