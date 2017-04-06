$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'

class SupportView extends Backbone.View
    el: '#content'

    render: =>
      logo = "<img src='images/cocoLogo.png' id='cslogo_ex-sm'>"
      Dialog.showDialog
        title: "#{logo} Coconut Support",
        text: "
        <div id='help_content'>
          <p>Need help with Coconut Mobile?</p>

          <p>The best place to start may be the <a target='_blank' href='http://docs.coconutsurveillance.org'>Coconut Surveillance documentation</a> website. There you will find information
          about deploying the system, using the mobile and analytics applications, and the software technology behind the System.
          Documentation can also be downloaded from this website in PDF format for use offline.</p>

          <p>Still need help? Visit the <a target='_blank' href='http://talk.coconutsurveillance.org'>Coconut Surveillance Community</a> to search for answers or to post a question to the
          community.</p>

          <p>Need expert technical assistance, help considering a new deployment, or have a great idea for collaboration?
          <a href='mailto:coconutsurveillance@rti.org'>Contact us</a> to discuss your needs and your ideas.</p>
        </div>
        ",
        neutral:
          title: "Close"

      $("#orrsDiag_content").css("top",'250px')
module.exports = SupportView
