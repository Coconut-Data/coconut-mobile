_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
moment = require 'moment'
formatDistance = require('date-fns/formatDistance')
parse = require('date-fns/parse')

#$.DataTable = require('datatables')()
global.Tabulator = require 'tabulator-tables'

Question = require '../models/Question'
ResultCollection = require '../models/ResultCollection'

class ResultsView extends Backbone.View
  initialize: ->
    @question = new Question()

  el: '#content'

  render: =>
    metrics = await @getMetrics() 
    @$el.html "
      <style>
        h3, h4{
          margin-top:15px;
          margin-right: 10px;
          padding-top: 5px;
          float:left;
          color: rgb(63, 81, 181);
          line-height: 15px;
        }

/*        h4{ color: #{Coconut.colors.primary1}; } */
        /* Fixes problem with android's refresh on swipe 'feature' */
        body{ overflow-y: hidden; }

        th.header { text-align: left; }
        td a { text-decoration: none; }

        /*

        table.dataTable thead .sorting, table.dataTable thead .sorting_asc, table.dataTable thead .sorting_desc, table.dataTable thead .sorting_asc_disabled, table.dataTable thead .sorting_desc_disabled {
          background-position: center left;
        }

        table.results { margin: 10px auto; }
        table.center {
          margin: auto;
        }
        table#results_metrics { font-size: 1.0em;}
        .mdl-tabs__tab { font-size: 0.8em; }
        .stats-card-wide.mdl-card {
          width: 100%;
          min-height: 150px;
          background: linear-gradient(to bottom, #fff 0%, #dcdcdc 100%);

        }
        */
      </style>
      <div>
        <a href='##{Coconut.databaseName}/new/result/#{@question.id}' class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored f-left coconut-btn' data-upgraded=',MaterialButton'>
          <i class='mdi mdi-plus mdi-24px'></i>
        </a>
        <h4 class='content_title'>
          #{@question.id}
        </h4>
      </div>

      <div>
        <b>#{metrics["Total completed"]}</b> #{@question.id} result#{if metrics["Total completed"].length is 1 then "" else "s"} have been completed (<b>#{metrics["Total completed today"]}</b> today, <b>#{metrics["Total completed this week"]}</b> this week). The most recent completion was <b>#{metrics["Most recently completed result"]}</b>. There #{if metrics["Total not completed"] is 1 then "is" else "are"} <b>#{metrics["Total not completed"]}</b> incomplete result#{if metrics["Total not completed"] is 1 then "" else "s"} 

      </div>

      <div style='margin-top: 20px;display:inline-block'>
        All #{@question.id} results for this device are shown below. Click on the row to edit or the plus icon above to create a new one.
      </div>
      <div id='results-table'></div>
    "
    @loadResults()

  getMetrics: =>
    metrics = {
      "Total completed": 0
      "Total completed this week": 0
      "Total completed today": 0
      "Most recently completed result": "N/A"
      "Total not completed": 0
    }

    Coconut.database.query "results",
      startkey: [@question.id],
      endkey: [@question.id,{},{}]
    .then (result) =>
      _(result.rows).each (row) ->
        if row.key[1] is false
          metrics["Total not completed"] += 1
        else
          resultDate = moment(row.key[2])

          metrics["Total completed"] +=1
          metrics["Total completed this week"] +=1 if moment().isSame(resultDate, 'week')
          metrics["Total completed today"] +=1 if moment().isSame(resultDate, 'day')
          metrics["Most recently completed result"] = resultDate.fromNow()
      Promise.resolve(metrics)

  loadResults: =>

    Coconut.database.allDocs
      startkey: "result"
      endkey: "result\uf000"
      include_docs: true
    .then (result) =>
      columns = for title,field of @question.summaryFieldsMappedToResultPropertyNames()
        title: title
        field: field
        headerFilter: "input"

      columns.unshift
        title: "Time Modified"
        field: "lastModifiedAt"
        sorter: "date"
        sorterParams:
          format: "YYYY-MM-DD HH:mm:ss"
        formatter: (cell) =>
          "#{formatDistance(parse(cell.getValue(), "yyyy-MM-dd HH:mm:ss", new Date()), new Date(), {addSuffix: true})}"

      columns.unshift
        title: "Complete"
        field: "complete"
        formatter: "tickCross"
        sorter: "boolean"

      columns.push
        title: ""
        formatter: (cell) =>
          "
          <a href='##{Coconut.databaseName}/delete/result/#{cell.getData()._id}' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon mdl-button--accent'>
            <i class='mdi mdi-delete'></i>
          </a>
          "

      data = _(result.rows)
        .chain()
        .filter (row) =>
          row.doc.question is @question.id
        .pluck "doc"
        .value()

      @tabulator = new Tabulator "#results-table",
        maxHeight: "100%"
        data: data
        columns: columns
        initialSort: [
          {column: "complete"}
          {column: "lastModifiedAt"}
        ]
        rowClick: (e,row) =>
          Coconut.router.navigate("#{Coconut.databaseName}/edit/result/#{row.getData()._id}", {trigger:true})

module.exports = ResultsView
