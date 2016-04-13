_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Utils = require '../Utils'
Result = require './Result'

class ResultCollection

  fetch: (options) =>
    queryOptions = _.extend {
      # defaults, overridden by options
      include_docs: false
      startkey: [options.question,options.isComplete is true]
      endkey: [options.question,options.isComplete is true, {}]
    }, options

    fields = (Coconut.questions.find (question) ->
      question.id is options.question
    ).summaryFieldKeys()

    Coconut.database.query "results", queryOptions,
      (error,result) =>
        @results = _(result.rows).map (row) ->
          returnVal = _.object(fields,row.value)
          returnVal._id = row.id
          new Result(returnVal)
        options.success()

  each: (arg) ->
    _(@results).each arg

  ResultCollection.load = (options) ->
    Coconut.questions.fetch
      error: (error) -> console.log "Error loading Coconut.questions: #{JSON.stringify error}"
      success: ->
        options.success() if Coconut.questions.length is 0

        designDocs = {
          results: """
            (doc) ->
              if doc.collection is "result" and doc.question and doc.createdAt
                summaryFields = (#{
                  if Coconut.questions.length is 0
                    "[]"
                  else
                    Coconut.questions.map (question) ->
                      "if doc.question is '#{question.id}' then #{JSON.stringify question.summaryFieldKeys()}"
                    .join " else "
                })

                summaryResults = []
                for field in summaryFields
                  summaryResults.push doc[field]

                emit([doc.question, doc.complete is true, doc.createdAt], summaryResults)
          """
          resultsByQuestionNotCompleteNotTransferredOut: (document) ->
            if document.collection is "result"
              if document.complete isnt "true"
                if document.transferred?
                  emit document.question, document.transferred[document.transferred.length-1].to
                else
                  emit document.question, null

          rawNotificationsConvertedToCaseNotifications: (document) ->
            if document.hf and document.hasCaseNotification
              emit document.date, null

          resultsByQuestionAndField: (document) ->
            if document.collection is "result" and document.question
              _(document).chain().keys().each (field) ->
                return if field.substring(0,1) is "_" unless field is "_id"
                return if _([
                  "createdAt"
                  "lastModifiedAt"
                  "user"
                  "question"
                  "collection"
                  "savedBy"
                  "complete"
                ]).contains field
                emit [document.question,field,document[field]], document[field]
        }

        finished = _.after _(designDocs).size(), ->
          options.success()
        
        _(designDocs).each (designDoc,name) ->
          designDoc = Utils.createDesignDoc name, designDoc
          Utils.addOrUpdateDesignDoc designDoc,
            success: -> finished()


module.exports = ResultCollection
