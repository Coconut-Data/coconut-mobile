_ = require 'underscore'

$ = require 'jquery'
Cookie = require 'js-cookie'

#Backbone = require 'backbone'
#Backbone.$  = $
moment = require 'moment'
sha1 = require 'sha1'

User = require './User'

class Result
  constructor: (@data) ->
    @set
      collection: "result"
    unless @data.createdAt
      @set
        createdAt: moment(new Date()).format(Coconut.config.get "date_format")
    unless @data.lastModifiedAt
      @set
        lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")

  fetch: =>
    throw "can't fetch result without an ID" unless @data._id
    Coconut.database.get @data._id
    .then (result) =>
      @set(result)

  set: (values) =>
    _(@data).extend(values)

  get: (property) =>

    return null unless Coconut.currentUser?
    original = @data[property]

    return original if Coconut.currentUser.hasRole "cleaner"

    if original? and Coconut.currentUser.hasRole "reports"
      if _.contains(Coconut.identifyingAttributes, property)
        return sha1(original)

    return original

  question: -> @get("question")

  tags: ->
    tags = @get("Tags")
    return tags.split(/, */) if tags?
    return []

  complete: ->
    return true if _.include(@tags(), "complete")
    complete = @get("complete")
    complete = @get("Complete") if typeof complete is "undefined"
    return false if complete is null or typeof complete is "undefined"
    return true if complete is true or complete.match(/true|yes/)

  shortString: ->
    # see ResultsView.coffee to see @string get set
    result = @string
    if result.length > 40 then result.substring(0,40) + "..." else result

  summaryKeys: (question) ->

    relevantKeys = question.summaryFieldKeys()
    if relevantKeys.length is 0
      relevantKeys = _.difference (_.keys result.toJSON()), [
        "_id"
        "_rev"
        "complete"
        "question"
        "collection"
      ]

    return relevantKeys

  summaryValues: (question) ->
    return _.map @summaryKeys(question), (key) =>
      returnVal = @get(key) || ""
      if typeof returnVal is "object"
        returnVal = JSON.stringify(returnVal)
      returnVal


  toJSON: ->
    json = _(@data).clone()
    return json if Coconut.currentUser.hasRole "admin"
    if Coconut.currentUser.hasRole "reports"
      _.each json, (value, key) =>
        if value? and _.contains(Coconut.identifyingAttributes, key)
          json[key] = sha1(value)

    return json

  # support: save(object), save(key, value), and save(). Catch if options is passed
  save: (key,value,options) ->
    alert("callback deprecated") if options?
    if _(key).isObject()
      @set key
    else if key? and value?
      @set {"#{key}", value}

    @set
      user: Cookie('current_user')
      savedBy: Cookie('current_user')
      lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")

    unless @data._id
      @set
        _id: "result-#{Coconut.instanceId}-#{Date.now()}"


    Coconut.database.upsert @data._id, (currentValue) =>
      _(currentValue).extend @data

module.exports = Result
