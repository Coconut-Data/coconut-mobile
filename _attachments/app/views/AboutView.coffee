$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Dialog = require '../../js-libraries/modal-dialog'

class AboutView extends Backbone.View
    el: '#content'

    render: =>
      logo = "<img src='images/cocoLogo.png' id='cslogo_ex-sm'>"
      Dialog.showDialog
        title: "#{logo} Coconut Mobile",
        text: "
        <div id='version'>Version 1.0</div>
        <div id='license'>
          <p><i class='material-icons'>copyright</i> Copyright 2012-2017 RTI International. </p>
          <p>RTI International is a registered trademark and a trade name of Research Triangle Institute.</p>
          <div>Licensed under the Apache License, Version 2.0 (the 'License');<br />
          you may not use this file except in compliance with the License.<br />
          You may obtain a copy of the License at</div><br />
          <div><a target='_blank' href='http://www.apache.org/licenses/LICENSE-2.0'>http://www.apache.org/licenses/LICENSE-2.0</a></div><br />
          <div>Unless required by applicable law or agreed to in writing, software
          distributed under the License is distributed on an 'AS IS' BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        </div><br />
        <div>See the License for the specific language governing permissions and limitations under the License.</div><br />
        <div id='acknowledgements'>Acknowledgements and Credits.</div>
        <div>The development of Coconut Surveillance has been funded by RTI International and the U.S. President’s
Malaria Initiative. Coconut Surveillance has been developed in close collaboration with the Zanzibar Malaria Elimination Programme.</div>
        ",
        neutral:
          title: "Close"

      $("#orrsDiag_content").css("top",'360px')
module.exports = AboutView
