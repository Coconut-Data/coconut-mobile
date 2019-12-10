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

  name: (userId) ->
    userId = "user.#{userId}" unless userId.match(/^user\./)
    @get(userId).get("name")

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

  for name, designDocFunction of designDocs
    designDoc = Utils.createDesignDoc name, designDocFunction
    await Coconut.database.upsert designDoc._id, (existingDoc) =>
      return false if _(designDoc.views).isEqual(existingDoc?.views)
      designDoc

  new Promise (resolve) =>
    Coconut.users.fetch
      success: -> 
        resolve()

module.exports = UserCollection
