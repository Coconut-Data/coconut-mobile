_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Cookie = require 'js-cookie'

class User extends Backbone.Model
  url: "/user"

  username: ->
    @get("_id").replace(/^user\./,"")

  district: ->
    @get("district")

  passwordIsValid: (password) ->
    @get("password") is password

  isAdmin: ->
    _(@get("roles")).include "admin"

  hasRole: (role) ->
    _(@get("roles")).include role

  nameOrUsername: ->
    @get("name") or @username()

  login: ->
    User.currentUser = @
    Cookie('current_user', @username())
    Cookie('current_password', @get "password")
    $("span#user").html @username()
    $('#district').html @get "district"
    $("a[href=#logout]").show()
    $("a[href=#login]").hide()
    if @isAdmin() then $("#manage-button").show() else $("#manage-button").hide()
    if @hasRole "reports"
      $("#top-menu").hide()
      $("#bottom-menu").hide()

  refreshLogin: ->
    @login()

User.isAuthenticated = (options) ->
  current_user_cookie = Cookie('current_user')
  if current_user_cookie? and current_user_cookie isnt ""
    user = new User
      _id: "user.#{Cookie('current_user')}"
    user.fetch
      success: =>
        user.refreshLogin()
        options.success(user)
      error: (error) ->
        # current user is invalid (should not get here)
        console.error "Could not fetch user.#{Cookie('current_user')}: #{error}"
        # If username is invalid then we need to logout because the current encrypted database has the same username and will never allow access
        Coconut.database.info().then (databaseInfo) ->
          if Cookie('current_user') is databaseInfo.db_name
            $('.coconut-mdl-card__title').html "Wrong username <i style='padding-left:10px' class='material-icons'>mood_bad</i>"
            _.delay ->
              Coconut.router.navigate("logout",true)
            ,2000
        #options?.error()
  else
    # Not logged in
    options.error() if options.error?

User.logout = ->
  Cookie('current_user',"")
  $("span#user").html ""
  $('#district').html ""
  $("a[href=#logout]").hide()
  $("a[href=#login]").show()
  User.currentUser = null

module.exports = User
