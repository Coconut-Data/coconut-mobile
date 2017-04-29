$ = require 'jquery'
s = require 'underscore.string'

Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'

class SetupView extends Backbone.View

  fields: [
    "Cloud URL"
    "Application Name"
    "Cloud Username"
    "Cloud Password"
  ]

  options = {}

  el: '#content'

  render: =>
    @$el.html "
      <h3 style='text-align: center; font-size: 1.7em'>Install Coconut Project</h3>
      <div id='message'></div>
      <div id='form'>
        <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' style='font-size: 200%; width:330px; margin: 0px auto; padding:15px'>
        #{
          _(@fields).map (field) =>
            "
              <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
                <input class='mdl-textfield__input' id='#{s.underscored(field)}' autocapitalize='off' type='#{"password" if field.includes("Password")}'/>
                <label class='mdl-textfield__label' for='#{s.underscored field}'>#{field}</label>
              </div>
            "
          .join ""
        }
          <div class='mdl-card__actions'>
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent' id='install' type='button'>Install</button> &nbsp;
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect cancel_button' id='cancel_button' type='button'>Cancel</button> &nbsp;
            <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect cancel_button' id='help_button'><i class='material-icons'>help</i></button>
          </div>
        </div>
      </div>
      <div id='spinner'></div>
    "
    componentHandler.upgradeDom()

  events:
    "click #install": "install"
    "click .cancel_button": "cancel"
    "click #cancel_delete, #cancel_error": "cancel_deleteDB"
    "click button#destroy": "destroyApp"
    "click #help_button": "showHelp"

  cancel_deleteDB: ->
    $("#message").hide()
    @$el.find("div.mdl-card").show()
    $("#spinner").hide()

  cancel: ->
    Coconut.router.navigate("", true)

  prefill: (httpType, options) ->
    _(options).each (value , key) ->
      $("##{s.underscored(key)}").val(value)
      $("##{s.underscored(key)}").parent().addClass "is-dirty" if value and value isnt ""
    $("#cloud_url").val $("#cloud_url").val().replace(/^(http:\/\/)/, httpType + "://")


  destroyApp: =>
    $("#message").hide()
    applicationName = $("#"+s.underscored("Application Name")).val()
    $("#spinner").show().html "
        <center>
          <h4>Removing  #{applicationName}</h4>
          <h4 id='status'></h4>
          <div class='spin mdl-spinner mdl-js-spinner is-active'></div>
        </center>
    "
    componentHandler.upgradeDom()
    Coconut.destroyApplicationDatabases
      applicationName: applicationName
      success: =>
        # TODO make a fading out message
        $("#message").html "<h4 style='text-align: center'>#{applicationName} Removed</h4>"
        $("#message h4").fadeOut 3000
        @install()

  getOptions: ->
    options = @options || {}
    _(@fields).each (field) ->
      options[field] = $("##{s.underscored(field)}").val()
    return options

  installUrl: ->
    @options = @getOptions()
    httpType = if @options["Cloud URL"].match(/https:\/\//)
      "https"
    else
      "http"

    @options["Cloud URL"] = @options["Cloud URL"].replace(/http(s)*:\/\//, "")


  install: ->
    @installUrl()
    applicationName = $("#"+s.underscored("Application Name")).val()
    $('#install_status').show()

    $("#spinner").html "<center>Checking to see if #{applicationName} already exists</center>"
    PouchDB.allDbs().then (dbs) =>
      if _(dbs).includes "coconut-#{applicationName}"
        @$el.find("div.mdl-card").hide()
        @$el.find("#form").show()
        $("#spinner").hide()
        $("#message").show().html "
          <div class='setup_message'>
            <p class='errMsg' style = 'font-size: 18px'>Application #{applicationName} has already been installed.</p>
            <p>You can delete all data for #{applicationName} to recreate or you can change the Application Name field.</p>
            <div class='mdl-card__actions'>
              <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--colored' id='destroy'>Delete #{applicationName} </button> &nbsp;
              <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect' id='cancel_delete'>Cancel </button>
            </div>
          </div>
        "
      else
        @$el.find("div.mdl-card").hide()
        $("#spinner").show().html "
            <center>
              <h3 style='font-size: 24px'>Installing #{applicationName}</h3>
              <div id='install_status'>
                <h4 id='status'></h4>
                <div id='percent' style='margin-bottom: 30px'>( 0 of 0 )</div>
                <div class='spin mdl-spinner mdl-js-spinner is-active'></div>
              </div>
            </center>
        "
        componentHandler.upgradeDom()
        $("#log").hide().html ""

        Coconut.createDatabases
          params: @options
          error: (error) ->
            $("#message").show().html "
                <div class='setup_message'>
                  <div class='errMsg m-b-10'>Error installing #{applicationName}.</div>
                  <div>#{error}</div>
                  <div style='padding: 30px 0px'>Please review your form inputs.</div>
                  <div class='mdl-card__actions'>
                    <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect' id='cancel_error'>Back to Form</button>
                  </div>
                </div>
                "
            $('#install_status').hide()
          success: =>
            $('#spinner').hide()
            $("#message").show().html "<h4>#{applicationName} Installed</h4>"
            @$el.find("h4").fadeOut 3000
            _.delay ->
              Coconut.router.navigate "##{applicationName}", trigger: true
              ## hack to reload page so that all_Dbs database is reloaded. See issue# 141
              window.location.reload()
            , 1000

  showHelp: (e) ->
    Dialog.showDialog
      title: "About Install Coconut Project",
      text: "Coconut works offline, but first, you need to connect it to a Coconut server. Then Coconut will download everything that it needs to run on your device. After this, you only need a connection when you sync your data.
      <br /><br />Please contact your system administrator if you do not know these connection settings."
      neutral:
        title: "Close"

    $("#orrsDiag_content").css("top",'20%')
module.exports = SetupView
