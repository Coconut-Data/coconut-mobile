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
          width:50%;
          margin: 0px auto;
        }
        #login_message{
          margin-top: 20px;
          margin-bottom: 20px;
        }
        #login_form input{
          font-size: 200%;
          display: block;
        }
        .coconut-mdl-card{
          padding:10px;
        }
        #login_button{
          font-size:200%

        }
      </style>
      <div class='mdl-card mdl-shadow--8dp coconut-mdl-card' id='login_wrapper'>
        <div class='mdl-card__title coconut-mdl-card__title'></div>
        <form id='login_form'>

          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
            <input class='mdl-textfield__input' type='text' id='username' name='username'>
            <label class='mdl-textfield__label' for='username'>Username</label>
          </div>

          <div class='mdl-textfield mdl-js-textfield mdl-textfield--floating-label'>
            <input class='mdl-textfield__input' type='password' id='password' name='password'>
            <label class='mdl-textfield__label' for='password'>Password</label>
          </div>

          <div class='mdl-card__actions'>
            <button type='button' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--accent' id='login_button'>Login</button>
          </div>
        </form>
      </div>
    "

    componentHandler.upgradeDom()

  events:
    "click #login_button": "login"

  updateNavBar: ->

  # Note this needs hashing and salt for real security
  login: ->
    loginData = Form2js.form2js('login_form')
    #loginData = $('#login_form').toObject()
    user = new User
      _id: "user.#{loginData.username}"

    user.fetch
      success: =>
        # User exists
        if user.passwordIsValid loginData.password
          user.login()

          @callback.success()
        else
          $('.coconut-mdl-card__title').html "Wrong password <i style='padding-left:10px' class='material-icons'>mood_bad</i>"
      error: =>
          $('.coconut-mdl-card__title').html "Wrong username <i style='padding-left:10px' class='material-icons'>mood_bad</i>"

module.exports = LoginView
