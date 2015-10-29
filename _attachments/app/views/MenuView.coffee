_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

User = require '../models/User'

class MenuView extends Backbone.View

  render: =>
    @$el.html "
      <div id='navbar' data-role='navbar'>
        <ul></ul>
      </div>
    "

    Coconut.questions.fetch
      success: =>
        $(".mdl-layout__header-row").html(
          "<a style='position:absolute; top:0px; right:0px;' class='mdl-navigation__link' href='##{Coconut.databaseName}/sync'><i class='mdl-color-text--accent material-icons'>sync</i>Sync</a><br/>" + Coconut.questions.map (question,index) ->
            "
              <span class='mdl-layout-title'>#{question.id}</span>
              <button onClick='document.location=\"##{Coconut.databaseName}/new/result/#{escape(question.id)}\"' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                <i class='material-icons'>add</i>
              </button>
              <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='hdrbtn'>
                <i class='material-icons'>more_vert</i>
              </button>
              <ul class='mdl-menu mdl-js-menu mdl-js-ripple-effect mdl-menu--bottom-right' for='hdrbtn'>
                <li class='mdl-menu__item'>
                  <a href='##{Coconut.databaseName}/show/results/#{escape(question.id)}'>Results (<span id='complete_results'></span>)</a>
                </li>
              </ul>
            "
          .join(" ")
        )

        componentHandler.upgradeDom()

        @update()

  update: ->
    User.isAuthenticated
      success: () ->
        Coconut.questions.each (question,index) =>

          Coconut.database.query "results",
            startkey: [question.id, true]
            endkey: [question.id, true, {}]
            include_docs: false
            (error,result) =>
              console.log error if error

              $("#complete_results").html result.rows.length

    ###
    Coconut.database.get "version", (error,result) ->
      if error
        $("#version").html "-"
      else
        $("#version").html result.version
    ###

module.exports = MenuView
