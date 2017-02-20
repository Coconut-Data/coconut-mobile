$ = require 'jquery'
s = require 'underscore.string'

Backbone = require 'backbone'
Backbone.$  = $

SetupView = require './SetupView'
Dialog = require './DialogView'

class SelectApplicationView extends Backbone.View

  el: '#content'

  events:
    "click button.mdl-chip__action": "deleteApplication"

  deleteApplication: (e) ->
    app_name = e.target.id.slice(4)
    alert("You selected to delete "+ app_name)

  render: =>
    PouchDB.allDbs()
      .then (dbs) =>
        applicationNames = _(dbs).chain().filter (dbName) ->
          dbName.match(/^coconut/) and not dbName.match(/-user./) and not dbName.match(/-plugins/)
        .map (dbName) ->
          dbName.replace(/coconut-/,"")
        .value()

        if applicationNames.length is 0
          setupView = new SetupView()
          setupView.render()
        else
          @$el.html "
            <h3 class='select_app'>Select a coconut application</h3>
            <p id='select_buttons'>
            #{
              _(applicationNames).map (applicationName) ->
                "<span class='mdl-chip mdl-chip--deletable'>
                   <span class='mdl-chip__text region'><a href='##{applicationName}'>#{applicationName}</a></span>
                   <button type='button' class='mdl-chip__action'>
                    <i class='material-icons' id='del_#{applicationName}'>cancel</i>
                   </button>
                </span>"
              .join ""
            }
            </p>

            <p class='text'> <span style='padding-right: 10px'>... or install a new one.</span>
              <a href='#setup' class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' data-upgraded=',MaterialButton'><i class='material-icons'>add</i></a>
            </p>
          "

module.exports = SelectApplicationView
