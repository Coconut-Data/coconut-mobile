$ = require 'jquery'
s = require 'underscore.string'
Dialog = require '../../js-libraries/modal-dialog'
Backbone = require 'backbone'
Backbone.$  = $
SetupView = require './SetupView'

class SelectApplicationView extends Backbone.View

  el: '#content'

  initialize: ->
   view = this

  events:
    "click button.mdl-chip__action": "deleteApplication"
    "destroy": "destroy"

  deleteApplication: (e) ->
    app_name = e.target.id.slice(4)
    Dialog.showDialog
      title: 'Delete Application'
      text: "You selected to delete <b>"+app_name+"</b>.<br />Are you sure?"
      negative:
        title: 'No'
      positive:
          title: 'Yes',
          onClick: (e) ->
            Dialog.showDialog
              title: "Removing #{app_name}",
              text: "Please wait..."
            Coconut.destroyApplicationDatabases
               applicationName: app_name
               success: =>
                 Dialog.showDialog
                   title: "#{app_name} Removed",
                   text: "click CLOSE to continue"
                   neutral:
                     title: "Close",
                     onClick: (e) ->
                       document.location.reload()

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
          $('.mdl-layout__drawer-button').hide()
          $('.mdl-layout__header-row').css('padding-left', '24px')
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
