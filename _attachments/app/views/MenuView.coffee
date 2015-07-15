_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Coconut = require '../Coconut'
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
          Coconut.questions.map (question,index) ->
            "
              <span class='mdl-layout-title'>#{question.id}</span>
              <button onClick='document.location=\"#new/result/#{escape(question.id)}\"' class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon'>
                <i class='material-icons'>add</i>
              </button>
              <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='hdrbtn'>
                <i class='material-icons'>more_vert</i>
              </button>
              <ul class='mdl-menu mdl-js-menu mdl-js-ripple-effect mdl-menu--bottom-right' for='hdrbtn'>
                <li class='mdl-menu__item'>
                  <a href='#show/results/#{escape(question.id)}'>Results (<span id='complete_results'></span>)</a>
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
            key: [question.id, true]
            include_docs: false
            (error,result) =>
              console.log error if error

              $("#complete_results").html result.rows.length

    Coconut.database.get "version", (error,result) ->
      if error
        $("#version").html "-"
      else
        $("#version").html result.version

module.exports = MenuView
