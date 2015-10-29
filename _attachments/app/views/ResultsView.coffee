_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'

$.DataTable = require('datatables')

Question = require '../models/Question'
ResultCollection = require '../models/ResultCollection'

class ResultsView extends Backbone.View
  initialize: ->
    @question = new Question()

  el: '#content'

  render: =>

    @$el.html "
      <style>
        h3{ 
          margin-top:0px;
          float:right;
          color: #{Coconut.colors.accent1};
        }

        h4{ 
          color: #{Coconut.colors.primary1};
        }
        /* Fixes problem with android's refresh on swipe 'feature' */
        body{
          overflow-y: hidden;
        }
      </style>

      <h3>#{@question.id}</h3>
      <h4>Summary statistics</h4>

      <table id='results_metrics'>
      </table>
      #{
        # Fill in the results_metrics table
        metrics = {
          "Total completed": 0
          "Total completed this week": 0
          "Total completed today": 0
          "Most recently completed result": null
          "Total not completed": 0
        }

        Coconut.database.query "results",
          {
            startkey: [@question.id],
            endkey: [@question.id,{},{}]
          },
          (error,result) =>
            _(result.rows).each (row) ->
              console.log row
              if row.key[1] is false
                metrics["Total not completed"] += 1
              else
                resultDate = moment(row.key[2])

                metrics["Total completed"] +=1
                metrics["Total completed this week"] +=1 if moment().isSame(resultDate, 'week')
                metrics["Total completed today"] +=1 if moment().isSame(resultDate, 'day')
                metrics["Most recently completed result"] = resultDate.fromNow()

            $("#results_metrics").html _(metrics).map( (value, metric) ->
              "
                <tr>
                  <td>#{metric}</td>
                  <td style='color:#{Coconut.colors.accent1}'>#{value}</td>
                </tr>
              "
            ).join("")
            $("#total-completed").html metrics["Total completed"]
            $("#total-not-completed").html metrics["Total not completed"]
        ""
      }
      <h4>Detailed results</h4>

      <div class='mdl-tabs mdl-js-tabs mdl-js-ripple-effect'>

        <div class='mdl-tabs__tab-bar'>
          <a href='#complete-panel' class='mdl-tabs__tab is-active'>Complete (<span id='total-completed''></span>)</a>
          <a href='#not-complete-panel' class='mdl-tabs__tab'>Not Complete (<span id='total-not-completed'></span>)</a>
        </div>

        <div class='mdl-tabs__panel is-active complete' id='complete-panel'>
          <br/>
          <table class='results complete-true tablesorter'>
            <thead><tr>
              " + _.map(@question.summaryFieldNames(), (summaryField) ->
                "<th class='header'>#{summaryField}</th>"
              ).join("") + "
              <th></th>

            </tr></thead>
            <tbody>
            </tbody>
          </table>
        </div>

        <div class='mdl-tabs__panel not-complete' id='not-complete-panel'>
          <br/>
          <table class='results complete-false tablesorter'>
            <thead><tr>
              " + _.map(@question.summaryFieldNames(), (summaryField) ->
                "<th class='header'>#{summaryField}</th>"
              ).join("") + "
              <th></th>
            </tr></thead>
            <tbody>
            </tbody>
          </table>
        </div>

      </div>
    "

    @loadResults(false)
    @loadResults(true)
  
  loadResults: (complete) ->
    results = new ResultCollection()
    results.fetch
      include_docs: "true"
      question: @question.id
      isComplete: complete
      success: =>
        $(".count-complete-#{complete}").html results.results.length
        results.each (result) =>

          $("table.complete-#{complete} tbody").append "
            <tr>
              #{
                _.map(result.summaryValues(@question), (value) ->
                  "<td><a href='##{Coconut.databaseName}/edit/result/#{result.id}'>#{value}</a></td>"
                ).join("")
              }
              <td><a href='##{Coconut.databaseName}/delete/result/#{result.id}' data-icon='delete' data-iconpos='notext'>Delete</a></td>
            </tr>
          "

        $("table.complete-#{complete}").dataTable()

module.exports = ResultsView
