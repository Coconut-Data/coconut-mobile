$ = require 'jquery'

Backbone = require 'backbone'
Backbone.$  = $

Form2js = require 'form2js'

User = require '../models/User'

class LoginView extends Backbone.View

  el: '#content'

  render: =>
    @$el.html "
      <style>
        #login_wrapper{
          font-size: 102%;
          width:350px;
          margin: 70px auto;
          padding: 25px;
        }
        #login_message{
          margin-top: 20px;
          margin-bottom: 20px;
        }
        #login_form input{
          font-size: 120%;
          display: block;
        }
        .coconut-mdl-card{
          padding:10px;
        }
        #login_actions {
          padding-top: 30px;
        }
        #login_button, #cancel_button{
          font-size:100%;
          width: 100%;
        }
      </style>
      <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' id='login_wrapper'>
        <div id='logo-title'><img src='images/cocoLogo.png' id='cslogo_sm'> Coconut</div>
        <div class='mdl-card__title coconut-mdl-card__title errMsg'></div>
        <form id='login_form'>

          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
            <input class='mdl-textfield__input' type='text' id='username' name='username' autofocus style='text-transform:lowercase;' on keyup='javascript:this.value=this.value.toLowerCase()'>
            <label class='mdl-textfield__label' for='username'>Username</label>
          </div>

          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
            <input class='mdl-textfield__input' type='password' id='password' name='password'>
            <label class='mdl-textfield__label' for='password'>Password</label>
          </div>

          <div class='mdl-card__actions' id='login_actions'>
            <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent' id='login_button'>Log in</button> &nbsp;
            <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect' id='cancel_button'>Cancel</button>
          </div>
        </form>
      </div>
    "
    componentHandler.upgradeDom()

  events:
    "click #login_button": "login"
    "click #cancel_button": "cancel"
    "keypress #password": "submitIfEnter"

  submitIfEnter: (event) ->
    @login() if event.which == 10 or event.which == 13

  cancel: ->
    Coconut.router.navigate("", true)
#    return document.location.reload()

  # Note this needs hashing and salt for real security
  login: =>
    # Useful for reusing the login screen - like for database encryption
    if $("#username").val() is "" or $("#password").val() is ""
      return @displayErr("Please enter a username and a password")
    loginData = Form2js.form2js('login_form')
    loginData.username = loginData.username.toLowerCase()

    Coconut.openDatabase
      username: loginData.username
      password: loginData.password
      success: =>
        @callback()
      error: =>
        @displayErr("Invalid username/password")

  displayErr: (msg) =>
    $('.coconut-mdl-card__title').html "<i style='padding-right:10px' class='material-icons'>error_outline</i> #{msg}"

  module.exports = LoginView
