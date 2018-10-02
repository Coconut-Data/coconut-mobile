_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'

User = require '../models/User'

class MenuView extends Backbone.View
  el: ".coconut-drawer"

  events:
    "click .mdl-navigation__link": "hideShowDrawer"

  hideShowDrawer: ->
    $(".mdl-layout__drawer").removeClass("is-visible")
    $(".mdl-layout__obfuscator").removeClass("is-visible")

  render: =>
    @$el.html "
      <header class='coconut-drawer-header'>
        <div class='clear'>
          <div class='f-left m-l-10'><img src='images/cocoLogo.png' id='cslogo_sm'></div>
          <div class='mdl-layout-title' id='drawer-title'>Coconut Mobile</div>
          <div id='version'>Version: 1.0.0 - <a href='https://github.com/ICTatRTI/coconut-mobile/commit/3acb15c'>3acb15c</a></div>
        </div>
        <div style='margin: 5px 0 0 25px'>
        Application: #{Coconut.databaseName}<br/>
        Logged in as: #{Coconut.currentUser?.nameOrUsername()}<br/>
        <div>Last sync: <span id='sync_sent_status'>#{Coconut.sync_status}</span></div>
        <div>Last get: <span id='sync_get_status'>#{Coconut.sync_get_status}</span></div>
        </div>
      </header>
      <nav class='coconut-navigation'>
          <div id='drawer_question_sets'></div>
          <hr/>
          <div id='drawer_general_menu'></div>
      </nav>
    "

    @questionLinks()
    @generalMenu()
    componentHandler.upgradeDom()
    @hideMenuOptions()
    Coconut.headerView?.update()

  hideMenuOptions: ->
    if Coconut.currentUser?.hasRole "reports"
      $("#top-menu").hide()
      $("#bottom-menu").hide()

    ###
    Coconut.database.get "version", (error,result) ->
      if error
        $("#version").html "-"
      else
        $("#version").html result.version
    ###

  generalMenu: ->
    $("#drawer_general_menu").html (
      _([
        "##{Coconut.databaseName}/sync,sync,Sync data"
        "##{Coconut.databaseName}/reset/database,alert,Reset database"
        "##{Coconut.databaseName}/manage,wrench,Manage"
        "##{Coconut.databaseName}/logout,logout,Logout"
      ]).map (linkData) ->
        [url,icon,linktext] = linkData.split(",")
        "<a class='mdl-navigation__link' href='#{url}' id='#{linktext.toLowerCase()}'><i class='mdl-color-text--blue-grey-400 mdi mdi-#{icon}'></i>#{linktext}</a>"
      .join("")
    )

  questionLinks: ->
    Coconut.questions.fetch
      success: =>
        $("#drawer_question_sets").html (Coconut.questions.map (question,index) ->
          new_url = "##{Coconut.databaseName}/new/result/#{escape(question.id)}"
          results_url = "##{Coconut.databaseName}/show/results/#{escape(question.id)}"
          spanID = question.id.replace(/\s/g,"_")
          "
            <div>
              <a class='mdl-navigation__link' href='#{results_url}'><span id='#{spanID}' class='#{spanID} mdl-badge' data-badge=''><i class='mdl-color-text--accent mdi mdi-star'></i>
              <span>#{question.id}</span></span></a>
            </div>
          "
        .join(" "))

module.exports = MenuView
