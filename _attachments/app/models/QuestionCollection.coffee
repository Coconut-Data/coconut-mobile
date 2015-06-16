_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Coconut = require '../Coconut'

Question = require './Question'
Utils = require '../Utils'

class QuestionCollection extends Backbone.Collection
  model: Question
  pouch:
    options:
      query:
        include_docs: true
        fun: "questions"

  parse: (response) ->
    _(response.rows).pluck("doc")

  QuestionCollection.load = (options) ->
    Coconut.questions = new QuestionCollection()

    questionsDesignDoc = Utils.createDesignDoc "questions", (doc) ->
      if doc.collection and doc.collection is "question"
        emit doc._id, doc.resultSummaryFields

    Utils.addOrUpdateDesignDoc questionsDesignDoc,
      success: ->
        Coconut.questions.fetch
          success: -> options.success()

module.exports = QuestionCollection
