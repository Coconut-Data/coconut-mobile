$ = require 'jquery'
s = require 'underscore.string'

Backbone = require 'backbone'
Backbone.$  = $

class SelectApplicationView extends Backbone.View

  el: '#content'

  render: =>
    PouchDB.allDbs()
      .then (dbs) =>
        applicationNames = _(dbs).chain().filter (dbName) ->
          dbName.match(/^coconut/) and not dbName.match(/-user./)
        .map (dbName) ->
          dbName.replace(/coconut-/,"")
        .value()

        if applicationNames.length is 0
          setupView = new SetupView()
          setupView.render()
        else
          @$el.html "
            <h1>Select a coconut application</h1>
            #{
              _(applicationNames).map (applicationName) ->
                "<a href='##{applicationName}'>#{applicationName}</a><br/>"
              .join ""
            }
            <br/>
            ...or <a href='#setup'>install a new one</a>.
          "

module.exports = SelectApplicationView
