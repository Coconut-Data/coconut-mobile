_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Coconut = require '../Coconut'
User = require '../models/User'

class MenuView extends Backbone.View

  el: '.question-buttons'

  events:
    "change" : "render"


  render: =>
    @$el.html "
      <div id='navbar' data-role='navbar'>
        <ul></ul>
      </div>
    "

    Coconut.questions.fetch
      success: =>
        @$el.find("ul").html(Coconut.questions.map (question,index) ->
          "<li><a id='menu-#{index}' href='#show/results/#{escape(question.id)}'><h2>#{question.id}<div id='menu-partial-amount'></div></h2></a></li>"
        .join(" "))

#        $(".question-buttons").navbar()
        @update()

  update: ->
    if Coconut.config.local.get("mode") is "mobile"
      User.isAuthenticated
        success: () ->
          Coconut.questions.each (question,index) =>

            
            Coconut.database.query "resultsByQuestionNotCompleteNotTransferredOut",
              key: question.id
              include_docs: false
              (error,result) =>
                console.log error if error

                total = 0
                _(result.rows).each (row) =>
                  transferredTo = row.value
                  if transferredTo?
                    if User.currentUser.id is transferredTo
                      total += 1
                  else
                    total += 1

                $("#menu-#{index} #menu-partial-amount").html total

    Coconut.database.get "version", (error,result) ->
      if error
        $("#version").html "-"
      else
        $("#version").html result.version

module.exports = MenuView
