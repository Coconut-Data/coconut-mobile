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
    # 3 options: edit partials, edit complete, create new
    @$el.html "
      <!--
      <style>
        table.results th.header, table.results td{
          font-size:150%;
        }
        .dataTables_wrapper .dataTables_length{
          display: none;
        }

        .dataTables_filter input{
          display:inline;
          width:300px;
        }

        a[role=button]{
          background-color: white;
          margin-right:5px;
          -moz-border-radius: 1em;
          -webkit-border-radius: 1em;
          border: solid gray 1px;
          font-family: Helvetica,Arial,sans-serif;
          font-weight: bold;
          color: #222;
          text-shadow: 0 1px 0 #fff;
          -webkit-background-clip: padding-box;
          -moz-background-clip: padding;
          background-clip: padding-box;
          padding: .6em 20px;
          text-overflow: ellipsis;
          overflow: hidden;
          white-space: nowrap;
          position: relative;
          zoom: 1;
        }

        a[role=button].paginate_disabled_previous, a[role=button].paginate_disabled_next{
          color:gray;
        }

        .dataTables_info{
          float:right;
        }

        .dataTables_paginate{
          margin-bottom:20px;
        }

      </style>
      -->

      <h3>Results for '#{@question.id}'</h3>

      <table id='results_metrics'>
      </table>
      #{
        # Fill in the results_metrics table
        metrics = {
          "Total completed": 0
          "Total completed for week": 0
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
                #metrics["Total completed for week"] +=1 if resultDate > #TODO
                #metrics["Total completed today"] +=1 if resultDate is #TODO
                metrics["Most recently completed result"] = resultDate.fromNow()

            $("#results_metrics").html _(metrics).map( (value, metric) ->
              "
                <tr>
                  <td>#{metric}</td>
                  <td>#{value}</td>
                </tr>
              "
            ).join("")
        ""
      }

      <div class='not-complete'>
        <h2>'#{@question.id}' Items Not Completed (<span class='count-complete-false'></span>)</h2>
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
      <div class='complete'>
        <h2>'#{@question.id}' Items Completed (<span class='count-complete-true'></span>)</h2>
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
    "

    @loadResults(false)
    @loadResults(true)
    @updateCountComplete()

  updateCountComplete: ->
    results = new ResultCollection()
    results.fetch
      question: @question.id
      isComplete: true
      success: =>
        console.log results
        $(".count-complete-true").html results.results.length
  
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
                  "<td><a href='#edit/result/#{result.id}'>#{value}</a></td>"
                ).join("")
              }
              <td><a href='#delete/result/#{result.id}' data-icon='delete' data-iconpos='notext'>Delete</a></td>
            </tr>
          "

        $("table.complete-#{complete}").dataTable()

module.exports = ResultsView
