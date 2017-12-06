$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Form2js = require 'form2js'

User = require '../models/User'

class LoginView extends Backbone.View

  el: '#content'

  render: =>
    @displayHeader()
    $('.mdl-layout__drawer-button').hide()
    @$el.html "
      <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' id='login_wrapper'>
        <div id='logo-title'><img src='images/cocoLogo.png' id='cslogo_sm'> Coconut</div>
        <div class='mdl-card__title coconut-mdl-card__title' id='loginErrMsg'></div>
        <form id='login_form'>

          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
            <input class='mdl-textfield__input' type='text' id='username' name='username' autofocus autocorrect='off' autocapitalize='none' style='text-transform:lowercase;'>
            <label class='mdl-textfield__label' for='username'>Username</label>
          </div>

          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
            <input class='mdl-textfield__input' type='password' id='password' name='password'>
            <label class='mdl-textfield__label' for='password'>Password</label>
          </div>

          <div class='mdl-card__actions' id='login_actions'>
            <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent' id='login_button'>Log in</button>
            <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect' id='login_cancel_button'>Cancel</button>
          </div>
        </form>
      </div>
    "
    componentHandler.upgradeDom()

  events:
    "click #login_button": "login"
    "click #login_cancel_button": "cancel"
    "keypress #password": "submitIfEnter"

  submitIfEnter: (event) ->
    @login() if event.which == 10 or event.which == 13

  cancel: ->
    Coconut.router.navigate("", true)
    return document.location.reload()

  # Note this needs hashing and salt for real security
  login: =>
    # Useful for reusing the login screen - like for database encryption
    if $("#username").val() is "" or $("#password").val() is ""
      return @displayErr("Please enter a username and a password")
    loginData = Form2js.form2js('login_form')
    loginData.username = loginData.username.toLowerCase()
    Coconut.toggleSpinner(true)
    Coconut.openDatabase
      username: loginData.username
      password: loginData.password
      success: =>
        Coconut.toggleSpinner(false)
        $('#login_wrapper').hide()
        @callback()
      error: =>
        Coconut.toggleSpinner(false)
        @displayErr("Invalid username/password")

  displayErr: (msg) =>
    $('.coconut-mdl-card__title').html "<i style='padding-right:10px' class='mdi mdi-information-outline mdi-36px'></i> #{msg}"

  displayHeader: =>
    $(".mdl-layout__header-row").html("<div id='appName'>#{Coconut.databaseName}</div>
      <div id='right_top_menu'>
        <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='top-menu-lower-right'>
          <i class='mdi mdi-dots-vertical mdi-36px'></i>
        </button>
        <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='top-menu-lower-right'>
          <li class='mdl-menu__item'><a id='refresh' class='mdl-color-text--blue-grey-400' onclick='window.location.reload()'><i class='mdi mdi-rotate-right mdi-24px'></i> Refresh screen</a></li>
        </ul>
      </div>
    ")
  module.exports = LoginView
