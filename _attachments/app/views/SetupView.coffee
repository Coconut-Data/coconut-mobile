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
      Enter the setup details below:<br/>
    "
    _(@fields).map (field) =>
      @$el.append "#{field}<input style='display:block' id='#{s.dasherize(field)}'/>"

    @$el.append "
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
    Coconut.destroyApplicationDatabases
      applicationName: applicationName
      success: =>
        # TODO make a fading out message
        document.location.reload()
  
  install: ->
    options =
      success: ->
        # TODO FADER
        @$el.html ""
        Coconut.router.navigate "", trigger: true
      actionIfDatabaseExists: ->
        applicationName = $("#"+s.dasherize("Application Name")).val()
        $("#message").html "
          Application #{applicationName} has already been installed.<br/>
          You can update the fields below or delete all data for #{applicationName}.<br/>
          <button id='destroy'>Delete #{applicationName} </button>
          <br/><br/>
        "
        

    _(@fields).each (field) ->
      options[field] = $("##{s.dasherize(field)}").val()

    Coconut.createDatabases options

module.exports = SetupView
