_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'

User = require '../models/User'

menuIcons = { 'Case Notification':'wifi', 'Facility':'local_hospital', 'Household':'home', 'Household Members':'person'}
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
        </div>
        <div style='margin: 5px 0 0 25px'>
        Logged in as: #{Coconut.currentUser.nameOrUsername()}<br/>
        Last sync: <span class='sync-sent-status'></span>
        </div>
      </header>
      <nav class='coconut-navigation'>
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
      </nav>
      "

#    @renderHeader()

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

#        @update()

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
