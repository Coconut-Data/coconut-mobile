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
          font-size: 200%;
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
          font-size:100%

        }
      </style>
      <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' id='login_wrapper'>
        <div class='mdl-card__title coconut-mdl-card__title'></div>
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
            <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent' id='login_button'>Login</button> &nbsp;
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

  updateNavBar: ->


  cancel: ->
    Coconut.router.navigate("", true)
    return document.location.reload()

  # Note this needs hashing and salt for real security
  login: =>
    # Useful for reusing the login screen - like for database encryption
    if $("#username").val() is "" or $("#password").val() is ""
      return $('.coconut-mdl-card__title').html "Please enter a username and password <i style='padding-left:10px' class='material-icons'>mood_bad</i>"

    loginData = Form2js.form2js('login_form')
    loginData.username = loginData.username.toLowerCase()

    Coconut.openDatabase
      username: loginData.username
      password: loginData.password
      success: =>
        Coconut.menuView.render()
        $('.mdl-layout__drawer-button').addClass('show')
        @callback()
      error: =>
        $('.coconut-mdl-card__title').html "Invalid username/password <i style='padding-left:10px' class='material-icons'>mood_bad</i>"
  module.exports = LoginView
