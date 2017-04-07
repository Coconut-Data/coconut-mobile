_ = require 'underscore'
global._ = _
$ = require 'jquery'
Backbone = require 'backbone'

class ManageView extends Backbone.View

  render: ->

    links = [
      "Get previously sent results from cloud, archive, get/cloud/results"
      "Send Backup, backup, send/backup"
      "Save Backup, get_app, save/backup"
    ]

    @$el.html "
      <style>
        .manageLink{
          display:block;
          margin: 10px;
        }
      </style>
      <div id='manageCard' class='mdl-card mdl-shadow--8dp coconut-mdl-card' style='font-size: 200%; width:330px; margin: 0px auto; margin-top: 50px; padding:10px'>
      </div>
    "

    @$("#manageCard").html( _(links).map (link) ->
      [text,icon,destination] = link.split(/,\s*/)

      "
        <button class='manageLink mdl-button mdl-js-button mdl-button--raised mdl-button--colored'>
          <a style='color:white; text-decoration:none' href='##{Coconut.databaseName}/#{destination}'>
            <i style='position:relative; bottom:2px;' class='mdl-color-text--accent material-icons'>
              #{icon}
            </i>
            #{text}
          </a>
        </button>
      "
    .join(""))

module.exports = ManageView
