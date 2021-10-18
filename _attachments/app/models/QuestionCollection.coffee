_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Question = require './Question'
global.Utils = require '../Utils'

class QuestionCollection extends Backbone.Collection
  model: Question
  pouch:
    options:
      query:
        include_docs: true
        fun: "questions"

  parse: (response) ->
    _(response.rows).pluck("doc")

  displayOrder: =>
    if JackfruitConfig?.questionDisplayOrder?
      for question in JackfruitConfig.questionDisplayOrder
        Coconut.questions.get question
    else
      if JackfruitConfig?.questionsToHide?
        Coconut.questions.filter (question) =>
          not JackfruitConfig.questionsToHide.includes(question.id)
      else
        Coconut.questions

  QuestionCollection.load = (options) ->
    Coconut.questions = new QuestionCollection()

    designDoc = Utils.createDesignDoc "questions", (doc) ->
      if doc.collection and doc.collection is "question"
        emit doc._id, doc.resultSummaryFields

    Coconut.database.upsert designDoc._id, (existingDoc) =>
      return false if _(designDoc.views).isEqual(existingDoc?.views)
      designDoc
    .then =>
      new Promise (resolve) =>
        Coconut.questions.fetch
          success: -> 
            Promise.all Coconut.questions.models.map (question) =>
              question.fetch() # Coconut.questions.fetch doesn't seem to call fetch which is overloaded so call it again
            resolve()

module.exports = QuestionCollection
