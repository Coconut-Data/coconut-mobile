$ = require 'jquery'
s = require 'underscore.string'
Dialog = require '../../js-libraries/modal-dialog'
Backbone = require 'backbone'
Backbone.$  = $
SetupView = require './SetupView'

class SelectApplicationView extends Backbone.View

  el: '#content'

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
              text: "<div>Please wait...</div><div class='mdl-progress mdl-js-progress mdl-progress__indeterminate'></div><br />"
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
    $('.mdl-layout__drawer-button').hide()
    $('#home_icon').hide()
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
            <h4 class='select_app'>Select a coconut application</h4>
            <p id='select_buttons'>
            #{
              _(applicationNames).map (applicationName) ->
                "<span class='mdl-chip mdl-chip--deletable'>
                   <span class='mdl-chip__text region'><a href='##{applicationName}'>#{applicationName}</a></span>
                   <button type='button' class='mdl-chip__action'>
                    <i class='mdi mdi-close-circle mdi-24px' id='del_#{applicationName}'></i>
                   </button>
                </span>"
              .join ""
            }
            </p>

            <p class='text'> <span style='padding-right: 10px'>... or install a new one.</span>
              <a href='#setup' class='mdl-button mdl-js-button mdl-button--fab mdl-button--mini-fab mdl-button--colored' data-upgraded=',MaterialButton'><i class='mdi mdi-plus mdi-36px'></i></a>
            </p>
          "

module.exports = SelectApplicationView
