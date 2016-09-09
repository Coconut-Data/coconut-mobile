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
      Coconut is an offline HTML5 application. This means that it works even when you are offline. But first, you need to set it up by pointing it at an existing cloud based Coconut server with a specific Coconut application to use. Once you've done that all of the resources required to use the app will be saved on your device. The only time you need to be online is when you sync.   
      <br/>
      <br/>
      <br/>
      <div id='message'></div>
      <div id='form'
        Enter the setup details below:<br/>
        <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' style='font-size: 200%; width:50%; margin: 0px auto; padding:10px'>
        #{
          _(@fields).map (field) =>
            "
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                <input class='mdl-textfield__input' id='#{s.underscored(field)}'/>
                <label class='mdl-textfield__label' for='#{s.underscored field}'>#{field}</label>
              </div>
            "
          .join ""
        }
          <div class='mdl-card__actions'>
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent' id='install' type='button'>Install</button>
          </div>
        </div>
      </div>
    "
    componentHandler.upgradeDom()
    
  events:
    "click #install": "install"
    "click #destroy": "destroy"

  prefill: (httpType, options) ->
    _(options).each (value , key) ->
      $("##{s.underscored(key)}").val(value)
      $("##{s.underscored(key)}").parent().addClass "is-dirty" if value and value isnt ""
    $("#cloud_url").val $("#cloud_url").val().replace(/^(http:\/\/)*/, httpType + "://")


  destroy: =>
    applicationName = $("#"+s.underscored("Application Name")).val()
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

  getOptions: ->
    options = {}
    _(@fields).each (field) ->
      options[field] = $("##{s.underscored(field)}").val()
    return options

  installUrl: ->
    options = @getOptions()
    httpType = if options["Cloud URL"].match(/https:\/\//)
      "https"
    else
      "http"

    options["Cloud URL"] = options["Cloud URL"].replace(/http(s)*:\/\//, "")
    Coconut.router.navigate "#setup/#{httpType}/#{options["Cloud URL"]}/#{options["Application Name"]}/#{options["Cloud Username"]}/#{options["Cloud Password"]}"
    
  
  install: ->
    @installUrl()
    applicationName = $("#"+s.underscored("Application Name")).val()

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

      actionIfDatabaseExists: (options) =>
        console.log options
        @$el.find("#form").show()
        @$el.find("#spinner").remove()
        $("#message").html "
          Application #{applicationName} has already been installed.<br/>
          You can update the fields below or delete all data for #{applicationName}.<br/>
          <button id='destroy'>Delete #{applicationName} </button>
          <br/><br/>
        "
        
    _(options).extend @getOptions()

    @$el.find("div.mdl-card").hide()
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
