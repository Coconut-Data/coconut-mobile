_ = require 'underscore'
global._ = _
$ = require 'jquery'
Backbone = require 'backbone'

class SettingsView extends Backbone.View
  
  render: ->
    
    Coconut.database.get "_local/settings"
    .then (result) ->
      @$el.html(
        "
          <table>
            <thead>
            </thead>
            <tbody>
        " +
        _(result).map (value, key) ->
          "
          <tr>
            <td>
              <input id='#{key}'>#{key}</input>
            </td>
          </tr>
          <tr>
            <td>
              <input id='#{value}'>#{value}</input>
            </td>
          </tr>
          "
        .join("") + "
            </tbody>
          </table>
        "
      )
    .catch (error) ->
      console.error error
    
module.exports = SettingsView
