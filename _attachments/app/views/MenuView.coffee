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
          <div id='version'>Version: 1.0.0</div>
        </div>
        <div style='margin: 5px 0 0 25px'>
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
    Coconut.headerView.update()

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

module.exports = MenuView
