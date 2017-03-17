_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

User = require '../models/User'

class MenuView extends Backbone.View

  render: =>
    $("header.coconut-drawer-header").html "
      <h2>Coconut Outbreak</h2>
      Logged in as: #{Coconut.currentUser.nameOrUsername()}<br/>
      Last sync: <span class='sync-sent-status'></span>
    "
    $("nav.coconut-navigation").html "

      <div id='drawer_question_sets'></div>
      <hr/>
      #{
        _([
          "##{Coconut.databaseName}/sync,sync,Sync data"
          "##{Coconut.databaseName}/logout,person,Logout"
          "##{Coconut.databaseName}/reset/database,warning,Reset database"
          "##{Coconut.databaseName}/manage,build,Manage"
        ]).map (linkData) ->
          [url,icon,linktext] = linkData.split(",")
          "<a class='mdl-navigation__link' href='#{url}'><i class='mdl-color-text material-icons'>#{icon}</i>#{linktext}</a>"
        .join("")
      }
    "

    $("nav.coconut-navigation").on "click",".mdl-navigation__link", ->
      $(".mdl-layout__drawer").removeClass("is-visible")

    @$el.html "
      <div id='navbar' data-role='navbar'>
        <ul></ul>
      </div>
    "

    @renderHeader()


    Coconut.questions.fetch
      success: =>

        $("#drawer_question_sets").html (Coconut.questions.map (question,index) ->
          new_url = "##{Coconut.databaseName}/new/result/#{escape(question.id)}"
          results_url = "##{Coconut.databaseName}/show/results/#{escape(question.id)}"
          "
            <div>
              <a class='drawer_question_set_link' href='#{new_url}'><i class='mdl-color-text--accent material-icons'>add</i></a>
              <a class='drawer_question_set_link' href='#{results_url}'><i class='mdl-color-text--accent material-icons'>insert_chart</i></a>
              <span class='drawer_question_set_name'>#{question.id}</span>
            </div>
          "
        .join(" "))

        componentHandler.upgradeDom()

        @update()

  renderHeader: ->
    $(".mdl-layout__header-row").html "
      <span id='app_title'>Coconut Mobile</span>
      <a style='position:absolute; top:0px; right:40px;' class='mdl-navigation__link' href='##{Coconut.databaseName}/sync'><i class='mdl-color-text--accent material-icons'>sync</i>Sync</a>
      <button id='top-menu-lower-right' class='mdl-button mdl-js-button mdl-button--icon'>
          <i class='material-icons'>more_vert</i>
      </button>
      <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='top-menu-lower-right'>
        <li class='mdl-menu__item'>About</li>
        <li class='mdl-menu__item'>Support</li>
        <li disabled class='mdl-menu__item'>Disabled Action</li>
        <li class='mdl-menu__item'>
          <a class='mdl-menu__item' id='logout' href='##{Coconut.databaseName}/logout'>Logout</a>
        </li>
      </ul>
    "

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
