$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

_ = require 'underscore'

User = require './User'
Utils = require '../Utils'

class UserCollection extends Backbone.Collection
  model: User
  pouch:
    options:
      query:
        include_docs: true
        fun: "users"

  parse: (response) ->
    _(response.rows).pluck("doc")

  district: (userId) ->
    userId = "user.#{userId}" unless userId.match(/^user\./)
    @get(userId).get("district")

UserCollection.load = (options) ->
  Coconut.users = new UserCollection()

  designDocs = {
    users: (doc) ->
      if doc.collection and doc.collection is "user"
        emit doc._id, null

    usersByDistrict: (doc) ->
      if doc.collection and doc.collection is "user"
        emit doc.district, [doc.name, doc._id.substring(5)]
  }

  Promise.all( _(designDocs).map (designDoc,name) ->
    designDoc = Utils.createDesignDoc name, designDoc
    Utils.addOrUpdateDesignDoc designDoc,
      success: -> 
        Coconut.users.fetch
          success: -> 
            Promise.resolve()
  )

module.exports = UserCollection
