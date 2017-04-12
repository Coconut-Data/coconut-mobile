_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'

$.DataTable = require('datatables')()

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
          margin-top:15px;
          margin-right: 10px;
          padding-top: 5px;
          float:left;
          color: rgb(63, 81, 181);
          line-height: 15px;
        }

        h4{
          color: #{Coconut.colors.primary1};
        }
        /* Fixes problem with android's refresh on swipe 'feature' */
        body{
          overflow-y: hidden;
        }

        th.header {
          text-align: left;
        }
        td a {
          text-decoration: none;
        }

        table.dataTable thead .sorting, table.dataTable thead .sorting_asc, table.dataTable thead .sorting_desc, table.dataTable thead .sorting_asc_disabled, table.dataTable thead .sorting_desc_disabled {
          background-position: center left;
        }
      </style>

      <h3 class='content_title'>
        #{@question.id}
      </h3>
      <a href='##{Coconut.databaseName}/new/result/#{@question.id}' class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' data-upgraded=',MaterialButton'><i class='material-icons'>add</i></a>
      <div class='clearfix'></div>
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
                  <td style='width: 280px'>#{metric}</td>
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

        <div class='mdl-tabs__tab-bar' id='results-tabs'>
          <a href='#complete-panel' class='mdl-tabs__tab'>Complete (<span id='total-completed'></span>)</a>
          <a href='#not-complete-panel' class='mdl-tabs__tab is-active'>Not Complete (<span id='total-not-completed'></span>)</a>
        </div>

        <div class='mdl-tabs__panel complete' id='complete-panel'>
          <br/>
          <table class='results complete-true tablesorter hover'>
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

        <div class='mdl-tabs__panel is-active not-complete' id='not-complete-panel'>
          <br/>
          <table class='results complete-false tablesorter hover'>
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
              <td style='text-align: center'><a href='##{Coconut.databaseName}/delete/result/#{result.id}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon mdl-button--accent'>
                <i class='material-icons'>delete</i>
              </a></td>
            </tr>
          "

        $("table.complete-#{complete}").dataTable({
          "columnDefs": [{"orderable": false, "targets": 2}]
        })

module.exports = ResultsView
