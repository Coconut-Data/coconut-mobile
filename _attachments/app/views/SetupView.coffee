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
      <h3>Install Coconut Project</h3>
      <div style='padding-bottom: 50px'>
      Coconut works offline, but first, you need to connect it to a Coconut server. Then Coconut will download everything that it needs to run on your device. After this, you only need a connection when you sync your data.
      <br />Please contact your system administrator if you do not know these connection settings.
      </div>
      <div id='message'></div>
      <div id='form'
        Enter the setup details below:<br/>
        <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' style='font-size: 200%; width:400px; margin: 0px auto; padding:25px'>
        #{
          passwordType = "type='password'"
          _(@fields).map (field) =>
            "
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                <input class='mdl-textfield__input' id='#{s.underscored(field)}' type='#{"password" if field.includes("Password")}'/>
                <label class='mdl-textfield__label' for='#{s.underscored field}'>#{field}</label>
              </div>
            "
          .join ""
        }
          <div class='mdl-card__actions'>
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent' id='install' type='button'>Install</button> &nbsp;
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect cancel_button' id='cancel_button' type='button'>Cancel</button>
          </div>
        </div>
      </div>
    "
    componentHandler.upgradeDom()

  events:
    "click #install": "install"
    "click .cancel_button": "cancel"
    "click #destroy": "destroy"

  cancel: ->
    Coconut.router.navigate("", true)

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
          <h3>Removing  #{applicationName}</h3>
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
        $("#content").html "<h3>#{applicationName} Removed</h3>"
        $("#content h3").fadeOut 1000
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
        <div class='errMsg'>
          Error installing #{applicationName}:<br/> #{error}
        </div>
        <br/><br/>
        "

      success: =>
        @$el.html "<h3>#{applicationName} Installed</h3>"
        @$el.find("h3").fadeOut 1000
        _.delay ->
          Coconut.router.navigate applicationName, trigger: true
        , 1000

      actionIfDatabaseExists: (options) =>
        @$el.find("#form").show()
        @$el.find("#spinner").remove()
        $("#message").html "
          <p style = 'font-size: 18px'>Application #{applicationName} has already been installed.<br/>
          You can update the fields below or delete all data for #{applicationName}.</p>
          <button class='mdl-button mdl-js-button mdl-button--raised mdl-button--colored' id='destroy'>Delete #{applicationName} </button> &nbsp;
          <button class='mdl-button mdl-js-button mdl-button--raised cancel_button'>Cancel </button>
          <br/><br/>
        "

    _(options).extend @getOptions()

    @$el.find("div.mdl-card").hide()
    @$el.append "
      <div id='spinner'>
        <center>
          <h3>Installing #{applicationName}</h3>
          <h4 id='status'></h4>
          <div style='height:200px;width:200px' class='mdl-spinner mdl-js-spinner is-active'></div>
        </center>
      </div>
    "
    componentHandler.upgradeDom()
    $("#log").html ""
    $("#log").hide()

    Coconut.createDatabases options

module.exports = SetupView
