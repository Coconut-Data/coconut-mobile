$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'
AboutView = require './AboutView'
User = require '../models/User'
SupportView = require './SupportView'

menuIcons = { 'Case Notification':'wifi', 'Facility':'local_hospital', 'Household':'home', 'Household Members':'person'}
class HeaderView extends Backbone.View
    el: ".mdl-layout__header-row"

    events:
      "click a#logout": "Logout"
      "click a#about": "About"
      "click a#support": "Support"

    Logout: ->
      Coconut.router.navigate "##{Coconut.databaseName}/logout", {trigger: true}

    About: ->
      Coconut.aboutView = new AboutView() if !Coconut.aboutView
      Coconut.aboutView.render()

    Support: ->
      Coconut.supportView = new SupportView() if !Coconut.supportView
      Coconut.supportView.render()

    render: =>
      @$el.html "
        <span class='mdl-layout-title' id='layout-title'>Coconut Mobile</span>
        <nav class='mdl-navigation'></nav>
        <div class='mdl-layout-spacer'></div>
        <div id='right_top_menu'>
          <a id='sync_icon' class='mdl-navigation__link' href='##{Coconut.databaseName}/sync'><i class='mdl-color-text--accent material-icons'>sync</i></a>
          <button class='mdl-button mdl-js-button mdl-js-ripple-effect mdl-button--icon' id='top-menu-lower-right'>
            <i class='material-icons'>more_vert</i>
          </button>
          <ul class='mdl-menu mdl-menu--bottom-right mdl-js-menu mdl-js-ripple-effect' for='top-menu-lower-right'>
            <li class='mdl-menu__item'><a id='about' class='mdl-color-text--blue-grey-400'><i class='material-icons'>info</i> About</a></li>
            <li class='mdl-menu__item'><a id='support' class='mdl-color-text--blue-grey-400'><i class='material-icons'>help</i> Support</a></li>
            <li class='mdl-menu__item' id='login_out'><a id='logout' class='mdl-color-text--blue-grey-400'><i class='material-icons'>exit_to_app</i> Logout</a></li>
          </ul>
        </div>
      "

      if Coconut.currentUser is null or Coconut.currentUser is undefined
        $('li.mdl-menu__item#login_out').hide()
        $('a#sync_icon').hide()
        $('.mdl-layout').addClass('mdl-layout--no-drawer-button')
        $('.mdl-layout__drawer-button').addClass('hide')
      else
        $('li.mdl-menu__item#login_out').show()
        $('a#sync_icon').show()
        $('.mdl-layout').removeClass('mdl-layout--no-drawer-button')
        $('.mdl-layout__drawer-button').show()

      if Coconut.questions
        navlinks = (Coconut.questions.map (question,index) ->
          results_url = "##{Coconut.databaseName}/show/results/#{escape(question.id)}"
          spanID = question.id.replace(/ /g,"_")
          "<a class='mdl-navigation__link top_links' href='#{results_url}'><span id='#{spanID}' class='mdl-badge' data-badge='0'><i class='mdl-layout--small-screen-only material-icons'>#{menuIcons[question.id]}</i> <span class='mdl-layout--large-screen-only'>#{question.id}</span></span></a>"
        .join(" "))
        $('nav.mdl-navigation').html(navlinks)

      componentHandler.upgradeDom()

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
module.exports = HeaderView
