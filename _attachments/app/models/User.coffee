_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
global.Cookie = require 'js-cookie'

class User extends Backbone.Model
  url: "/user"

  username: ->
    @get("_id").replace(/^user\./,"")

  district: ->
    @get("district")

  isAdmin: ->
    _(@get("roles")).include "admin"

  hasRole: (role) ->
    _(@get("roles")).include role

  nameOrUsername: ->
    @get("name") or @username()

User.isAuthenticated = ->
  Coconut.validateDatabase()
  .catch (error) ->
    # See if we have cookies that can login
    userCookie = Cookie.get('current_user')
    passwordCookie = Cookie.get('current_password')

    console.log "Trying to login with cookies"

    if userCookie and userCookie isnt "" and passwordCookie and passwordCookie isnt ""
      Coconut.openDatabase
        username: userCookie
        password: passwordCookie
      .then ->
        Promise.resolve()
    else
      throw "No saved user, must login"
  .then =>
    if Coconut.currentUser?
      Promise.resolve()
    else
      throw "No current user"

User.login = (options) ->
  new Promise (resolve) =>
    user = new User
      _id: "user.#{options.username}"
    user.fetch
      success: =>
        console.log "SETTING COOKIES"
        Coconut.currentUser = user
        Cookie.set('current_user', user.username())
        Cookie.set('current_password', options.password)
        resolve()
      error: (error) =>
        throw error

User.logout = ->
  Cookie.set('current_user',"")
  Cookie.set('current_password',"")
  Coconut.currentUser = null

module.exports = User
