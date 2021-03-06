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
      <h3>Syncing</h3>
      <h4 id='status'></h4>
      <div class='spin mdl-spinner mdl-js-spinner is-active'></div>
      </center>
    "
    componentHandler.upgradeDom()
    $("#log").html ""
    $("#log").hide()

  update: =>
    @sync.fetch
      success: =>
        Coconut.sync_status = if @sync.was_last_send_successful() then @sync.last_send_time() else "#{@sync.last_send_time()} - last attempt FAILED"
        Coconut.sync_get_status = if @sync.was_last_get_successful() then @sync.last_get_time() else "#{@sync.last_get_time()} - last attempt FAILED"
        $('#sync_sent_status').html(Coconut.sync_status)
        $('#sync_get_status').html(Coconut.sync_get_status)
      error: =>
        @sync.save()
        _.delay =>
          @update
        ,2000

module.exports = SyncView
