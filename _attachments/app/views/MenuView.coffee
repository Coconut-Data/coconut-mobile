_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

User = require '../models/User'

class MenuView extends Backbone.View
  menuIcons = { 'Case Notification':'wifi', 'Facility':'local_hospital', 'Household':'home', 'Household Members':'person'}

  render: =>
    $("header.coconut-drawer-header").html "
    <div class='clear'>
      <div class='f-left m-l-10'><img src='images/cocoLogo.png' id='cslogo_sm'></div>
      <div class='mdl-layout-title' id='drawer-title'>Coconut Mobile</div>
    </div>
    <div style='margin: 5px 0 0 25px'>
    Logged in as: #{Coconut.currentUser.nameOrUsername()}<br/>
    Last sync: <span class='sync-sent-status'></span>
    </div>
    "
    $("nav.coconut-navigation").html "

      <div id='drawer_question_sets'></div>
      <hr/>
      #{
        _([
          "##{Coconut.databaseName}/sync,sync,Sync data"
          "##{Coconut.databaseName}/reset/database,warning,Reset database"
          "##{Coconut.databaseName}/manage,build,Manage"
          "##{Coconut.databaseName}/logout,exit_to_app,Logout"
        ]).map (linkData) ->
          [url,icon,linktext] = linkData.split(",")
          "<a class='mdl-navigation__link' href='#{url}'><i class='mdl-color-text material-icons'>#{icon}</i>#{linktext}</a>"
        .join("")
      }
    "

    $("nav.coconut-navigation").on "click",".mdl-navigation__link", ->
      $(".mdl-layout__drawer").removeClass("is-visible")
      $(".mdl-layout__obfuscator").removeClass("is-visible")

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
<!--          <a class='drawer_question_set_link' href='#{new_url}'><i class='material-icons'>add</i></a> -->
              <a class='mdl-navigation__link' href='#{results_url}'><i class='mdl-color-text--accent material-icons'>#{menuIcons[question.id]}</i>#{question.id}</a>
<!--              <span class='drawer_question_set_name'>#{question.id}</span> -->
            </div>
          "
        .join(" "))

        componentHandler.upgradeDom()

        @update()

  renderHeader: ->
    # This section is only a demo and will be eventuallly dynamically generated in the plugin
    $(".mdl-layout__header-row").html "
      <span class='mdl-layout-title'>Coconut Mobile</span>
      <nav class='mdl-navigation mdl-layout--large-screen-only'>
        <a class='mdl-navigation__link top_links' href='##{Coconut.databaseName}/show/results/Case Notification'><span class='mdl-badge' data-badge='0'>Case Notification</span></a>
        <a class='mdl-navigation__link top_links' href='##{Coconut.databaseName}/show/results/Facility'><span class='mdl-badge' data-badge='1'>Facility</span></a>
        <a class='mdl-navigation__link top_links' href='##{Coconut.databaseName}/show/results/Household'><span class='mdl-badge' data-badge='10'>Household</span></a>
        <a class='mdl-navigation__link top_links' href='##{Coconut.databaseName}/show/results/Household%20Members'><span class='mdl-badge' data-badge='100'>Household Members</span></a>
      </nav>
      <div class='mdl-layout-spacer'></div>
      <div id='right_top_menu'>
        <a id='sync_icon' class='mdl-navigation__link' href='##{Coconut.databaseName}/sync'><i class='mdl-color-text--accent material-icons'>sync</i></a>
        <button id='top-menu-lower-right' class='mdl-button mdl-js-button mdl-button--icon'>
          <i class='material-icons'>more_vert</i>
        </button>
        <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='top-menu-lower-right'>
          <li class='mdl-menu__item'>About</li>
          <li class='mdl-menu__item'>Support</li>
          <li class='mdl-menu__item'>
            <a class='mdl-menu__item' id='logout' href='##{Coconut.databaseName}/logout'>Logout</a>
          </li>
        </ul>
      <div>
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
