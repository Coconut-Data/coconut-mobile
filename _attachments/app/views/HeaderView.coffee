$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'
AboutView = require './AboutView'
User = require '../models/User'
SupportView = require './SupportView'

class HeaderView extends Backbone.View
  el: ".mdl-layout__header-row"

  initialize: ->
    #hack to replace drawer button to use mdi icon.
    $('.mdl-layout__drawer-button i').removeClass('material-icons').addClass('mdi mdi-menu')

  events:
    "click a#logout": "Logout"
    "click a#about": "About"
    "click a#support": "Support"
    "click a#refresh": "Refresh"
#      "click a#home_icon": "homePage"

  homePage: ->
    Coconut.router.navigate("",true)

  Logout: ->
    $('nav.mdl-navigation').html("")
    Coconut.router.navigate "##{Coconut.databaseName}/logout", {trigger: true}

  About: ->
    Coconut.aboutView = new AboutView() if !Coconut.aboutView
    Coconut.aboutView.render()

  Support: ->
    Coconut.supportView = new SupportView() if !Coconut.supportView
    Coconut.supportView.render()

  Refresh: ->
    Backbone.history.loadUrl()

  render: =>
    @$el.html "
      <span class='mdl-layout-title' style='width:60px;font-size:.75em;overflow:hidden' id='layout-title'>#{titleize(Coconut.databaseName?.replace(/[-_]/,' ') or "Coconut")}</span>
      <a href='##{Coconut.databaseName}' id='home_icon' class='mdl-navigation__link top_links'>
         <span><i class='mdl-layout--small-screen-only mdi mdi-home mdi-36px' title='Home'></i></span>
         <span class='mdl-layout--large-screen-only'>Home</span>
      </a>
      <nav class='mdl-navigation'></nav>
      <div class='mdl-layout-spacer'></div>
      <div id='right_top_menu'>
        <span class='mdl-spinner mdl-js-spinner' id='syncing'></span>
        <a id='sync_icon' class='mdl-navigation__link' href='##{Coconut.databaseName}/sync'><i class='mdl-color-text--accent mdi mdi-sync mdi-48px'></i></a>
        <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='top-menu-lower-right'>
          <i class='mdi mdi-dots-vertical mdi-36px'></i>
        </button>
        <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='top-menu-lower-right'>
          <li class='mdl-menu__item'><a id='about' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-information mdi-24px'></i> About</a></li>
          <li class='mdl-menu__item'><a id='support' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-help mdi-24px'></i> Support</a></li>
          <li class='mdl-menu__item'><a id='refresh' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-rotate-right mdi-24px'></i> Refresh screen</a></li>
          <li class='mdl-menu__item' id='login_out'><a id='logout' class='mdl-color-text--blue-grey-400'><i class='mdi mdi-logout mdi-24px'></i> Logout</a></li>
        </ul>
      </div>
    "

    if Coconut.currentUser?
      $('li.mdl-menu__item#login_out').show()
      $('a#sync_icon').show()
      $('.mdl-layout').removeClass('mdl-layout--no-drawer-button')
      $('.mdl-layout__drawer-button').show()
    else
      $('li.mdl-menu__item#login_out').hide()
      $('a#sync_icon').hide()
      $('.mdl-layout').addClass('mdl-layout--no-drawer-button')
      $('.mdl-layout__drawer-button').addClass('hide')
      $('nav.mdl-navigation').html("")

    if Coconut.currentUser?
      @questionTabs()
#      @update()
    componentHandler.upgradeDom()

  toggleSyncIcon: (sync_on) ->
    if sync_on
      $('#syncing').addClass('is-active')
      $('#sync_icon').hide()
    else
      $('#syncing').removeClass('is-active')
      $('#sync_icon').show()

  questionTabs: ->

    if Coconut.questions
      $('nav.mdl-navigation').html( 
        Coconut.questions.displayOrder().map (question) =>
          results_url = "##{Coconut.databaseName}/show/results/#{escape(question.id)}"
          spanID = question.id.replace(/\s/g,"_")
          "
            <a class='mdl-navigation__link top_links' href='#{results_url}'>
              <span id='#{spanID}' class='mdl-badge' data-badge=''>
                <span class='material-icons'>#{question.get('icon') or "star"}</span>
                <span class='mdl-layout--large-screen-only'>#{question.id}</span>
              </span>
            </a>
          "
        .join("")
      )

  update: ->
    Coconut.questions.each (question,index) =>
      Coconut.database.query "results/results",
        startkey: [question.id, false]
        endkey: [question.id, false, {}]
        include_docs: false
        (error,result) =>
          console.log error if error
          $("span##{question.id.replace(/\s/g,'_')}").attr('data-badge', result.rows.length)

module.exports = HeaderView
