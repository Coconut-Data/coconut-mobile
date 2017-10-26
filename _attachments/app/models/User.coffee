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

  #login: ->
    #Coconut.currentUser = @
    #Cookie('current_user', @username())
    #Cookie('current_password', @get "password")


User.isAuthenticated = (options) ->
  Coconut.isValidDatabase
    error:  (error) ->
      # See if we have cookies that can login
      userCookie = Cookie('current_user')
      passwordCookie = Cookie('current_password')

      if userCookie and userCookie isnt "" and passwordCookie and passwordCookie isnt ""
        Coconut.openDatabase
          username: userCookie
          password: passwordCookie
          success: ->
            options.success()
          error: ->
            options.error()
      else
        options.error()
    success: ->
      if Coconut.currentUser?
        options.success()
      else
        options.error()

User.login = (options) ->
  user = new User
    _id: "user.#{options.username}"
  user.fetch
    success: =>
      Coconut.currentUser = user
      Cookie('stinky_sue', "peeyou")
      Cookie('current_user', user.username())
      Cookie('current_password', options.password)
      options.success()
    error: (error) =>
      options.error(error)

User.logout = ->
  Cookie('current_user',"")
  Cookie('current_password',"")
  Coconut.currentUser = null

module.exports = User
