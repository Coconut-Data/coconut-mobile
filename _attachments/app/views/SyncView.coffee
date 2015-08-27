_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Sync = require '../models/Sync'

class SyncView extends Backbone.View
  initialize: ->
    @sync = new Sync()

  el: '#content'

  render: =>
    @$el.html "
      <center>
      <h2>Syncing</h2>
      <h3 id='status'></h3>
      <div style='height:200px;width:200px' class='mdl-spinner mdl-js-spinner is-active'></div>
      </center>
    "
    componentHandler.upgradeDom()
    $("#log").html ""
    $("#log").hide()

  update: =>
    @sync.fetch
      success: =>
        $(".sync-sent-status").html if @sync.was_last_send_successful() then @sync.last_send_time() else "#{@sync.last_send_time()} - last attempt FAILED"
        $(".sync-get-status").html if @sync.was_last_get_successful() then @sync.last_get_time() else "#{@sync.last_get_time()} - last attempt FAILED"
      error: =>
        console.log "synclog doesn't exist yet, create it and re-render"
        @sync.save()
        _.delay(@update,1000)

module.exports = SyncView
