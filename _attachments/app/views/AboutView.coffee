$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'

class AboutView extends Backbone.View
    el: '#content'

    render: =>
      Dialog.showDialog
        title: "About Coconut",
        text: "Description of Coconut here..."
        neutral:
          title: "Close"
      $("#orrsDiag_content").css('top', '0%')

module.exports = AboutView
