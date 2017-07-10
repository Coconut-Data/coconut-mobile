# These need to be available to the window object for form logic
# # # #
global.SkipTheseWhen = ( argQuestions, result ) ->
  questions = []
  argQuestions = argQuestions.split(/\s*,\s*/)
  for question in argQuestions
    questions.push window.questionCache[question]
  disabledClass = "disabled_skipped"

  for question in questions
    if result
      question.addClass disabledClass
    else
      question.removeClass disabledClass

global.ResultOfQuestion = ( name ) -> return window.getValueCache[name]?() || null

# # # #



_ = require 'underscore'
global._ = _
s = require 'underscore.string'
$ = require 'jquery'
global.$ = $ # required for validations that use jquery
jQuery = require 'jquery'
Cookie = require 'js-cookie'
Awesomplete = require 'awesomplete'

Backbone = require 'backbone'
Backbone.$  = $
#CoffeeScript = require 'coffee-script' - this is loaded in index.html
Module = require 'module'

Form2js = require 'form2js'
moment = require 'moment'

#typeahead = require 'typeahead.js'

ResultCollection = require '../models/ResultCollection'

#
# This improves accuracy of GPS recording, see https://github.com/gwilson/getAccurateCurrentPosition
#
navigator.geolocation.getAccurateCurrentPosition = (geolocationSuccess, geolocationError, geoprogress, options) ->
  locationEventCount = 0
  lastCheckedPosition = null
  if navigator.geolocation.watchID != null
    navigator.geolocation.clearWatch navigator.geolocation.watchID
  options = options or {}

  checkLocation = (position) ->
    lastCheckedPosition = position
    locationEventCount = locationEventCount + 1
    if position.coords.accuracy <= options.desiredAccuracy and locationEventCount > 1
      clearTimeout timerID
      navigator.geolocation.clearWatch navigator.geolocation.watchID
      foundPosition position
    else
      geoprogress position
    return

  stopTrying = ->
    navigator.geolocation.clearWatch navigator.geolocation.watchID
    foundPosition lastCheckedPosition
    return

  onError = (error) ->
    clearTimeout timerID
    navigator.geolocation.clearWatch navigator.geolocation.watchID
    geolocationError error
    return

  foundPosition = (position) ->
    geolocationSuccess position
    return

  if !options.maxWait
    options.maxWait = 10000  # Default 10 seconds
  if !options.desiredAccuracy
    options.desiredAccuracy = 20  # Default 20 meters
  if !options.timeout
    options.timeout = options.maxWait  # Default to maxWait
  options.maximumAge = 0  # Force current locations only
  options.enableHighAccuracy = true  # Force high accuracy (otherwise, why are you using this function?)
  navigator.geolocation.watchID = navigator.geolocation.watchPosition(checkLocation, onError, options)
  timerID = setTimeout(stopTrying, options.maxWait)  # Set a timeout that will abandon the location loop

class QuestionView extends Backbone.View

  initialize: ->
    Coconut.resultCollection ?= new ResultCollection()
    @autoscrollTimer = 0

  el: '#content'

  triggerChangeIn: ( names ) ->

    for name in names
      elements = []
      elements.push window.questionCache[name].find("input, select, textarea, img")
      $(elements).each (index, element) =>
        event = target : element
        @actionOnChange event

  render: =>



    @primary1 = "rgb(63,81,181)"
    @primary2 = "rgb(48,63,159)"

    @accent1 = "rgb(230,33,90)"
    @accent2 = "rgb(194,24,91)"

    @$el.html "
    <style>
      div.question .mdl-textfield{
        width: inherit;
        display: block;
      }
      .mdl-textfield__input{
        width: 100%;
      }

      label, label.coconut-radio.mdl-radio, input, input.mdl-textfield__input{
        font-size: 1.1em;
      }

      input{
        width: 100%;
      }

      .message
      {
        color: white;
        font-weight: bold;
        padding: 10px;
        border: 1px #{@accent2} dotted;
        background: #{@accent2};
        display: none;
      }

      .message, label.radio{
        max-width: 620px;
      }

      label.mdl-nontextfield__label{
        display:block;
        color: #{@accent1};
        padding:20px 0px 20px;
        font-size: 1.3em;
      }

      label.mdl-nontextfield__label.has-value{
        color: #{@primary1};
        font-size:100%;
      }

      .mdl-textfield--floating-label.is-focused .mdl-textfield__label, .mdl-textfield--floating-label.is-dirty .mdl-textfield__label{
        font-size:100%;
      }

      label.mdl-textfield__label{
        display:block;
        color:#{@accent1};
        padding:20px 0px 20px;
        font-size: 1.3em;
        /* font-size:125%; */
      }

      div.radio label.mdl-textfield__label{
       font-size:150%;
       color:#{@accent1};
      }

      .is-dirty label.mdl-textfield__label{
       color:#{@primary1};
      }

      #question-view .mdl-textfield__label{
        position: inherit;
      }

      .coconut-radio{
        margin: 10px;
      }

      .mdl-radio__label{
        line-height:normal;
      }

      label.radio-option,label.checkbox-option {
        border-radius:20px;
        display:inline-block;
        padding:4px 11px;
        border: 1px solid black;
        cursor: pointer;
        text-decoration: none;
        width:250px;
        line-height:100%;
        vertical-align: top;
      }
      label.radio-option {
        width: inherit;
        font-size: 100%;
      }

      input[type='radio']:checked + label {
        color: white;
        background-color:#ddd;
        background: #{@primary1};
        background-image: -webkit-gradient(linear,left top,left bottom,from(#{@primary1}),to(#{@primary2}));
        background-image: -webkit-linear-gradient(#{@primary1},#{@primary2});
        background-image: -moz-linear-gradient(#{@primary1},#{@primary2});
        background-image: -ms-linear-gradient(#{@primary1},#{@primary2});
        background-image: -o-linear-gradient(#{@primary1},#{@primary2});
      }

      input[type='radio'],input[type='checkbox']{
        height: 0px;
        width: 0px;
        margin: 0px;
      }

      input[type='checkbox']:checked + label {
        color: white;
        background-color:#ddd;
        background: #{@primary1};
        background-image: -webkit-gradient(linear,left top,left bottom,from(#{@primary1}),to(#{@primary2}));
        background-image: -webkit-linear-gradient(#{@primary1},#{@primary2});
        background-image: -moz-linear-gradient(#{@primary1},#{@primary2});
        background-image: -ms-linear-gradient(#{@primary1},#{@primary2});
        background-image: -o-linear-gradient(#{@primary1},#{@primary2});
      }
      input[type='checkbox']{
        height: 0px;
      }

      #question-set-complete:checked + label {
        color: #{@primary1};
        background:none;
      }

      .question-set-complete-label{
        color: #{@accent2};
        font-size: 1.5em;
      }
      #question-set-complete{
        /* Triple-sized Checkboxes */
        -ms-transform: scale(3); /* IE */
        -moz-transform: scale(3); /* FF */
        -webkit-transform: scale(3); /* Safari and Chrome */
        -o-transform: scale(3); /* Opera */
        height:20px;
        width: 15px;
        margin: 10px;
      }

      div.question.radio{
        padding-top: 8px;
        padding-bottom: 8px;
      }
      .tt-hint{
        display:none
      }
      .tt-dropdown-menu{
        width: 100%;
        background-color: lightgray;
      }
      .tt-suggestion{
        background-color: white;
        border-radius:20px;
        display:block;
        padding:4px 11px;
        border: 1px solid black;
        cursor: pointer;
        text-decoration: none;
      }
      .tt-suggestion .{
      }

      button.next_error.mdl-button{
        bottom: 0px;
        position: relative;
      }

      div.message {
        font-size:20px;
      }

      .awesomplete ul{
        background-color:white;
        position:absolute;
        z-index:10;
        width: 95%;
        list-style:none;
        margin-top: 3px;
        border-left: 2px inset;
        border-bottom: 2px outset;
        border-right: 1px outset;
        border-top: 0px;
        font-size: 10px;
      }

      .awesomplete li{
        padding: 10px;
        font-size: 200%;
      }

      .awesomplete mark{
        background-color:white;
        color: gray;
      }

      .location .mdl-button{
        position:relative;
        margin-bottom: 10px;
      }

      #{
        @model.get("styles") or ""
      }

      span.visually-hidden{
        display:none;
      }


    </style>
    <div class='question_container'>
      <div style='position:fixed; right:5px; color:white; padding:20px; z-index:5' id='messageText'>
      </div>

      <div style='position:fixed; right:5px; color:white; background-color: #333; padding:20px; display:none; z-index:10' id='messageText'>
        Saving...
      </div>


      <h3 class='content_title'>#{@model.id}</h3>
      <div id='askConfirm'></div>
      <div id='question-view'>
        <form id='questions'>
          #{@toHTMLForm(@model)}
        </form>
      </div>
    </div>
    "

    componentHandler.upgradeDom()
    # Hack since upgradeDom doesn't add is-dirty class to previously filled in fields
    _.delay =>
      $('input[type=text]').filter( -> this.value isnt "").closest('div').addClass('is-dirty')
      $('input[type=number]').filter( -> this.value isnt "").closest('div').addClass('is-dirty')
      @updateLabelClass()
    , 500

    #Load data into form
    Form2js.js2form 'questions', @result.toJSON()

    @updateCache()

    # for first run
    @updateSkipLogic()

    # skipperList is a list of questions that use skip logic in their action on change events
    skipperList = []

    if @model.get("action_on_questions_loaded")? and @model.get("action_on_questions_loaded") isnt ""
      CoffeeScript.eval @model.get "action_on_questions_loaded"

    $(@model.get("questions")).each (index, question) =>

      # remember which questions have skip logic in their actionOnChange code
      skipperList.push(question.safeLabel()) if question.actionOnChange().match(/skip/i)

      if question.get("action_on_questions_loaded")? and question.get("action_on_questions_loaded") isnt ""
        console.debug question.get "action_on_questions_loaded"
        CoffeeScript.eval question.get "action_on_questions_loaded"

    # Trigger a change event for each of the questions that contain skip logic in their actionOnChange code
    @triggerChangeIn skipperList

    autocompleteElements = []
    _.each $("input[type='autocomplete from list']"), (element) ->
      new Awesomplete element,
        list: $(element).attr("data-autocomplete-options").replace(/\n|\t/,"").split(/, */)
        minChars: 1
        filter: Awesomplete.FILTER_STARTSWITH

      autocompleteElements.push element

    _.each $("input[type='autocomplete from code']"), (element) ->
      new Awesomplete element,
        list: eval($(element).attr("data-autocomplete-options"))
        minChars: 1
        filter: Awesomplete.FILTER_STARTSWITH

    _.each $("input[type='autocomplete from previous entries']"), (element) =>
      Coconut.database.query "resultsByQuestionAndField",
        startkey: [@model.get("id"),$(element).attr("name")]
        endkey: [@model.get("id"),$(element).attr("name"), {}]
      .catch (error) ->
        console.log "Error while doing autcomplete from previous entries for"
        console.log element
        console.log error
      .then (result) ->
        new Awesomplete element,
          list: _(result.rows).chain().pluck("value").unique().value()
          minChars: 1
          filter: Awesomplete.FILTER_STARTSWITH

    _.each autocompleteElements, (autocompeteElement) =>
      autocompeteElement.blur =>
        @autoscroll autocompeteElement
    $('input, textarea').attr("readonly", "true") if @readonly

    # Without this re-using the view results in staying at the old scroll position
    $("main").scrollTop(0)

  events:
    "change #question-view input"    : "onChange"
    "change #question-view select"   : "onChange"
    "change #question-view textarea" : "onChange"
    "click #question-view button:contains(+)" : "repeat"
    #"click #question-view a:contains(Get current location)" : "getLocation"
    "click .location button" : "getLocation"
    "click .next_error"   : "runValidate"
    "click .validate_one" : "onValidateOne"

  runValidate: -> @validateAll()

  onChange: (event) =>

    @updateLabelClass()

    $target = $(event.target)

    #
    # Don't duplicate events unless 1 second later
    #
    eventStamp = $target.attr("id")

    return if eventStamp == @oldStamp and (new Date()).getTime() < @throttleTime + 1000

    @throttleTime = (new Date()).getTime()
    @oldStamp     = eventStamp

    targetName = $target.attr("name")

    if targetName == "complete"

      allQuestionsPassValidation = @validateAll()

      # Update the menu
      Coconut.headerView.update()
      @actionOnChange(event)
      @save()
      @updateSkipLogic()

      if allQuestionsPassValidation
        if @model.get("action_on_questions_loaded")? and @model.get("action_on_questions_loaded") isnt ""
          CoffeeScript.eval @model.get "action_on_questions_loaded"
        onValidatedComplete = @model.get("onValidatedComplete")
        if onValidatedComplete
          console.log "Evaling: #{onValidatedComplete}"
          _.delay ->
            CoffeeScript.eval onValidatedComplete
          ,1000
      else
        $("#question-set-complete").prop("checked", false)
    else
      messageVisible = window.questionCache[targetName].find(".message").is(":visible")
# Hack by Mike to solve problem with autocomplete fields being validated before
      @actionOnChange(event)
      _.delay =>
        unless messageVisible
          wasValid = @validateOne
            key: targetName
            autoscroll: false
            button: "<button type='button' data-name='#{targetName}' class='validate_one'>Validate</button>"
          console.log "Saving"
          @save()
          @updateSkipLogic()
          @autoscroll(event) if wasValid
      , 500


  onValidateOne: (event) ->
    $target = $(event.target)
    name = $(event.target).attr('data-name')
    @validateOne
      key : name
      autoscroll: true
      leaveMessage : false
      button : "<button type='button' data-name='#{name}' class='validate_one'>Validate</button>"

  validateAll: () ->

    isValid = true

    for key in window.keyCache

      questionIsntValid = not @validateOne
        key          : key
        autoscroll   : isValid
        leaveMessage : false

      if isValid and questionIsntValid
        isValid = false

    @completeButton isValid

    $("[name=complete]").parent().scrollTo() if isValid # parent because the actual object is display:none'd by jquery ui

    return isValid


  validateOne: ( options ) =>

    key          = options.key          || ''
    autoscroll   = options.autoscroll   || false
    button       = options.button       || "<button type='button' class='next_error mdl-button mdl-js-button mdl-button--raised mdl-button--colored'>Next Error</button>"
    leaveMessage = options.leaveMessage || false

    $question = window.questionCache[key]
    $message  = $question.find(".message")

    message = @isValid(key)
    try
      message = @isValid(key)
    catch e
      alert "isValid error in #{key}\n#{e}"
      message = ""

    if $message.is(":visible") and leaveMessage
      if message is "" then return true else return false

    if message is ""
      $message.hide()
      if autoscroll
        @autoscroll $question
      return true
    else
      $message.show().html("
        #{message}
        #{button}
      ").find("button")

      try
        @scrollToElement $message
      catch e
        console.log "error", e
        console.log "Scroll error with 'this'", @

      return false

  scrollToElement: _.debounce (element) ->
    $('main').animate
      scrollTop: $("main").scrollTop() + element.offset().top-$("header").height()
  , 500, true


  isValid: ( question_id ) ->

    return unless question_id
    result = []

    questionWrapper = window.questionCache[question_id]

    # early exit, don't validate labels
    return "" if questionWrapper.hasClass("label")

    question        = $("[name=#{question_id}]", questionWrapper)

    type            = $(questionWrapper.find("input").get(0)).attr("type")
    labelText       =
      if type is "radio" or "checkbox"
        # No idea what's going on here
        #$("label[for=#{question.attr("id").split("-")[0]}]", questionWrapper).text() || ""
        if question.attr("id")
          $("label[for=#{question.attr("id").split("-")[0]}]", questionWrapper).contents().filter( -> @nodeType is 3)[0].nodeValue or ""
      else
        $("label[for=#{question.attr("id")}]", questionWrapper)?.text()
    required        = questionWrapper.attr("data-required") is "true"
    validation      = unescape(questionWrapper.attr("data-validation"))
    validation      = null if validation is "undefined"

    value           = window.getValueCache[question_id]()

    #
    # Exit early conditions
    #

    # don't evaluate anything that's been skipped. Skipped = valid
    return "" if not questionWrapper.is(":visible")

    # "" = true
    return "" if question.find("input").length != 0 and (type == "checkbox" or type == "radio")

    result.push "'#{labelText}' is required." if required && (value is null or value.length is 0) unless question_id is "Location"

    if validation? && validation isnt ""

      try
        validationFunctionResult = (CoffeeScript.eval("(value) -> #{validation}", {bare:true}))(value)
        result.push validationFunctionResult if validationFunctionResult?
      catch error
        return '' if error == 'invisible reference'
        alert "Validation error for #{question_id} with value #{value}: #{error}. Validation logic is: #{validation}"

    if result.length isnt 0
      return result.join("<br>") + "<br>"

    return ""

  scrollToQuestion: (question) ->
    # hack upon hack!
    @autoscroll $(question).prev()

  autoscroll: (event) ->
    # DISABLED!!
    return

    clearTimeout @autoscrollTimer

    # Some hacks in here to try and make it work
    if event.jquery
      $div = event
      window.scrollTargetName = $div.attr("data-question-name") || $div.attr("name")
    else
      $target = $(event.target)
      window.scrollTargetName = $target.attr("name")
      $div = window.questionCache[window.scrollTargetName]

    console.log $div

    @$next = $div.next()

    if not @$next.is(":visible") and @$next.length > 0
      safetyCounter = 0
      while not @$next.is(":visible") and (safetyCounter+=1) < 100
        @$next = @$next.next()

    if @$next.is(":visible")
      return if window.questionCache[window.scrollTargetName].find(".message").is(":visible")
      $(window).on( "scroll", => $(window).off("scroll"); clearTimeout @autoscrollTimer; )
      @autoscrollTimer = setTimeout(
        =>
          $(window).off( "scroll" )
          @$next.scrollTo().find("input[type=text],input[type=number]").focus()
        1000
      )

  # takes an event as an argument, and looks for an input, select or textarea inside the target of that event.
  # Runs the change code associated with that question.
  actionOnChange: (event) ->

    nodeName = $(event.target).get(0).nodeName
    $target =
      if nodeName is "INPUT" or nodeName is "SELECT" or nodeName is "TEXTAREA"
        $(event.target)
      else
        $(event.target).parent().parent().parent().find("input,textarea,select")

    # don't do anything if the target is invisible
    # For some reason radios aren't visible - could be a bug here if a radio is hidden and this shouldn't run
    return unless $target.is(":visible") or $target.attr("type") is "radio"

    name = $target.attr("name")
    $divQuestion = $(".question [data-question-name=#{name}]")
    code = $divQuestion.attr("data-action_on_change")
    try
      value = ResultOfQuestion(name)
    catch error
      return if error == "invisible reference"

    return if code == "" or not code?
    code = "(value) -> #{code}"
    try
      newFunction = CoffeeScript.eval.apply(@, [code])
      newFunction(value)
    catch error
      name = ((/function (.{1,})\(/).exec(error.constructor.toString())[1])
      message = error.message
      alert "Action on change error in question #{$divQuestion.attr('data-question-id') || $divQuestion.attr("id")}\n\n#{name}\n\n#{message}"

  updateSkipLogic: ->

    for name, $question of window.questionCache

      skipLogicCode = window.skipLogicCache[name]
      continue if skipLogicCode is "" or not skipLogicCode?

      try
        result = eval(skipLogicCode)
      catch error
        if error == "invisible reference"
          result = true
        else
          name = ((/function (.{1,})\(/).exec(error.constructor.toString())[1])
          message = error.message
          alert "Skip logic error in question #{$question.attr('data-question-id')}\n\n#{name}\n\n#{message}"

      if result
        $question[0].style.display = "none"
      else
        $question[0].style.display = ""

  currentData: ->
    currentData = Form2js.form2js('questions', ".", false)

    # HACK Form2js doesn't work for checkboxes with multiple values
    # Check if any values are checkboxes, then overwrite with correct value
    _(currentData).each (value,key) ->
      if $(".checkbox[name=#{key}]").length > 0
        currentData[key] = _($(".checkbox[name=#{key}]:checked")).map (element) ->
          $(element).val()

    return currentData

  # We throttle to limit how fast save can be repeatedly called
  save: _.throttle( ->
      currentData = @currentData()

      # Make sure lastModifiedAt is always updated on save
      currentData.lastModifiedAt = moment(new Date()).format(Coconut.config.get "date_format")
      currentData.savedBy = Cookie('mobile_current_user')
      @result.save currentData,
        success: (model) =>
          $("#messageText").slideDown().fadeOut()
          Coconut.router.navigate("#{Coconut.databaseName}/edit/result/#{model.id}",false)
          if ($('[name=complete]').prop("checked"))
            # Return to Summary page after completion
            Coconut.router.navigate("#{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.question())}",true)
          # Update the menu
          Coconut.headerView.update()
        error: (error) ->
          console.debug error
          console.error error
    , 1000)

  completeButton: ( value ) ->
    if $('[name=complete]').prop("checked") isnt value
      $('[name=complete]').click()

  toHTMLForm: (questions = @model, groupId) ->
    window.skipLogicCache = {}
    # Need this because we have recursion later
    questions = [questions] unless questions.length?
    _.map(questions, (question) =>
      repeatable = if question.repeatable() == "true" then "<button>+</button>" else ""

      unless question.type()? and question.label()? and question.label() != ""
        newGroupId = question_id
        newGroupId = newGroupId + "[0]" if question.repeatable()
        return "
          <div data-group-id='#{question_id}' class='question group'>
            #{@toHTMLForm(question.questions(), newGroupId)}
            <hr/>
            <div style='padding-top:20px'>
              <input name='complete' id='question-set-complete' type='checkbox' value='true'></input>
              <label class='question-set-complete-label' for='question-set-complete'>Complete</label>
            </div>
          </div>
          #{repeatable}
        "
      else
        name = question.safeLabel()
        return if name is "complete" and question.type() is "checkbox" # Complete now added automatically
        window.skipLogicCache[name] = if question.skipLogic() isnt '' then CoffeeScript.compile(question.skipLogic(),bare:true) else ''
        question_id = question.get("id")
        if question.repeatable() == "true"
          name = name + "[0]"
          question_id = question.get("id") + "-0"
        if groupId?
          name = "group.#{groupId}.#{name}"
        return "
          <div
            #{
            if question.validation()
              "data-validation = '#{escape(question.validation())}'" if question.validation()
            else
              ""
            }
            data-required='#{question.required()}'
            class='question #{question.type?() or ''} question-#{question_id} mdl-textfield mdl-js-textfield mdl-textfield--floating-label'
            data-question-name='#{name}'
            data-question-id='#{question_id}'
            data-action_on_change='#{_.escape(question.actionOnChange())}'

          >
          <div class='message'></div>
          #{
          "<label class='#{question.type()} mdl-nontextfield__label' type='#{question.type()}' for='#{question_id}'>#{question.label()} #{if question.required() is 'true' then '*' else ''}</label>" unless ~question.type().indexOf('hidden')
          }
          #{
            switch question.type()
              when "textarea"
                "<input name='#{name}' type='text' id='#{question_id}' value='#{_.escape(question.value())}'></input>"
# Selects look lame - use radio buttons instead or autocomplete if long list
#              when "select"
#                "
#                  <select name='#{name}'>#{
#                    _.map(question.get("select-options").split(/, */), (option) ->
#                      "<option>#{option}</option>"
#                    ).join("")
#                  }
#                  </select>
#                "
              when "select"
                if @readonly
                  question.value()
                else

                  html = "<select>"
                  for option, index in question.get("select-options").split(/, */)
                    html += "<option name='#{name}' id='#{question_id}-#{index}' value='#{option}'>#{option}</option>"
                  html += "</select>"
              when "radio"
                if @readonly
                  "<input class='mdl-radio__button' name='#{name}' type='text' id='#{question_id}' value='#{question.value()}'></input>"
                else
                  options = question.get("radio-options")
                  _.map(options.split(/, */), (option,index) ->
                    "
                      <label class='mdl-radio mdl-js-radio mdl-js-ripple-effect' for='#{question_id}-#{index}'>
                      <input class='mdl-radio__button' type='radio' name='#{name}' id='#{question_id}-#{index}' value='#{_.escape(option)}'/>
                      <span class='mdl-radio__label' style='padding-right: 10px'>#{option} </span>
                      </label>
                    "
                  ).join("")


              when "checkbox"
                if @readonly
                  "<input class='radioradio' name='#{name}' type='text' id='#{question_id}' value='#{question.value()}'></input>"
                else
                  options = question.get("checkbox-options")
                  _.map(options.split(/, */), (option,index) ->
                    "
                      <input class='checkbox' type='checkbox' name='#{name}' id='#{question_id}-#{index}' value='#{_.escape(option)}'/>
                      <label class='checkbox checkbox-option' for='#{question_id}-#{index}'>#{option}</label>

                    "
                  ).join("")

              when "autocomplete from list", "autocomplete from previous entries", "autocomplete from code"
                "
                  <!-- autocomplete='off' disables browser completion -->
                  <input autocomplete='off' name='#{name}' id='#{question_id}' type='#{question.type()}' value='#{question.value()}' data-autocomplete-options='#{question.get("autocomplete-options")}'></input>
                  <ul id='#{question_id}-suggestions' data-role='listview' data-inset='true'/>
                "
              when "location"
                # If the page has a location, then immediately start trying to get the current location to give the device extra time to get a more accurate position
                @watchID = navigator.geolocation.getAccurateCurrentPosition(
                  -> ,
                  -> ,
                  -> ,
                  {desiredAccuracy:50,maxWait:60*5*1000}
                )

                "
                  <div>
                    <button type='button' class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>
                      Get current location
                    </button>
                  </div>
                  <div>
                    <label for='#{question_id}-description'>Description</label>
                    <input type='text' name='#{name}-description' id='#{question_id}-description'></input><p/>
                    #{
                      _.map(["latitude", "longitude","accuracy"], (field) ->
                        "
                        <div>
                        <label for='#{question_id}-#{field}'>#{s.capitalize(field)}</label>
                        <input readonly='readonly' type='number' name='#{name}-#{field}' id='#{question_id}-#{field}'></input>
                        </div><p/>
                        "
                      ).join("")
                    }
                    #{
                      _.map(["altitude", "altitudeAccuracy", "heading", "timestamp"], (field) ->
                        "<input type='hidden' name='#{name}-#{field}' id='#{question_id}-#{field}'></input>"
                      ).join("")
                    }
                  </div>
                "

              when "image"
                "<img style='#{question.get "image-style"}' src='#{question.get "image-path"}'/>"
              when "label"
                ""
              when "text"
                "<input name='#{name}' id='#{question_id}' type='text' class='mdl-textfield__input' value='#{question.value()}'></input>"
              when "number"
                "<input name='#{name}' id='#{question_id}' type='number' class='mdl-textfield__input' value='#{question.value()}'></input>"
              else
                "<input name='#{name}' id='#{question_id}' type='#{question.type()}' value='#{question.value()}'></input>"
          }
          </div>
          #{repeatable}
        "
    ).join("")

  updateLabelClass: ->

    _(["radio","checkbox"]).each (type) ->
      if $("input[type=#{type}]").filter( -> @checked is true ).length > 0
        $("input[type=#{type}]").siblings('label.mdl-nontextfield__label').addClass "has-value"
      else
        $("input[type=#{type}]").siblings('label.mdl-nontextfield__label').removeClass "has-value"

  updateCache: ->
    window.questionCache = {}
    window.getValueCache = {}
    window.$questions = $(".question")

    for question in window.$questions
      name = question.getAttribute("data-question-name")
      if name? and name isnt ""
        accessorFunction = {}
        window.questionCache[name] = $(question)


        # cache accessor function
        $qC = window.questionCache[name] # questionContext
        selects = $("select[name=#{name}]", $qC)
        if selects.length is 0
          inputs  = $("input[name=#{name}]", $qC)
          if inputs.length isnt 0
            type = inputs[0].getAttribute("type")
            if type is "radio"
              do (name, $qC) -> accessorFunction = -> $("input:checked", $qC).safeVal()
            else if type is "checkbox"
              do (name, $qC) -> accessorFunction = -> $("input:checked", $qC).map( -> $(this).safeVal())
            else
              do (inputs) -> accessorFunction = -> inputs.safeVal()
          else # inputs is 0
            do (name, $qC) -> accessorFunction = -> $(".textarea[name=#{name}]", $qC).safeVal()

        else # selects isnt 0
          do (selects) -> accessorFunction = -> selects.safeVal()

        window.getValueCache[name] = accessorFunction

    window.keyCache = _.keys(questionCache)

  repeat: (event) ->
    button = $(event.target)
    newQuestion = button.prev(".question").clone()
    questionID = newQuestion.attr("data-group-id")
    questionID = "" unless questionID?

    # Fix the indexes
    for inputElement in newQuestion.find("input")
      inputElement = $(inputElement)
      name = inputElement.attr("name")
      re = new RegExp("#{questionID}\\[(\\d)\\]")
      newIndex = parseInt(_.last(name.match(re))) + 1
      inputElement.attr("name", name.replace(re,"#{questionID}[#{newIndex}]"))

    button.after(newQuestion.add(button.clone()))
    button.remove()

  getLocation: (event) ->
    requiredAccuracy = 200
    # 3 minutes
    maxWait = 3*60*1000
    question_id = $(event.target).closest("[data-question-id]").attr("data-question-id")
    $("##{question_id}-description").val "Retrieving position, please wait."

    updateFormWithCoordinates = (geoposition) ->
      _.each ["longitude","latitude","accuracy"], (measurementName) ->
        $("##{question_id}-#{measurementName}").val(geoposition.coords[measurementName])


      $("##{question_id}-timestamp").val(moment(geoposition.timestamp).format("YYYY-MM-DD HH:mm:ss"))
      $.getJSON "https://secure.geonames.org/findNearbyPlaceNameJSON?lat=#{geoposition.coords.latitude}&lng=#{geoposition.coords.longitude}&username=mikeymckay&callback=?", null, (result) =>
        $("##{question_id}-description").val parseFloat(result.geonames[0].distance).toFixed(1) + " km from center of " + result.geonames[0].name

    onSuccess = (geoposition) =>
      $("label[type=location]").html "Household Location"
      updateFormWithCoordinates(geoposition)
      $("##{question_id}-description").val "Success"
      @save()
    onError = (error) ->
      $("##{question_id}-description").val "Error: #{JSON.stringify error}"
    onProgress = (geoposition) =>
      updateFormWithCoordinates(geoposition)
      $("label[type=location]").html "Household Location<div style='background-color:yellow'>Current accuracy is #{geoposition.coords.accuracy} meters - must be less than #{requiredAccuracy} meters. Make sure there are no trees or buildings blocking view to the sky.</div>" if geoposition.coords.accuracy > requiredAccuracy

    navigator.geolocation.clearWatch(@watchID)
    navigator.geolocation.getAccurateCurrentPosition(onSuccess,onError,onProgress,
        desiredAccuracy: requiredAccuracy
        maxWait: maxWait
    )

# jquery helpers

( ($) ->

  $.fn.scrollTo = (speed = 500, callback) ->
    try
      #$('main').animate {
      #  scrollTop: $(@).offset().top + 'px'
      #  }, speed, null, callback
    catch e
      console.log "error", e
      console.log "Scroll error with 'this'", @

    return @


  $.fn.safeVal = () ->

    if @is(":visible") or @parents(".question").filter( -> return not $(this).hasClass("group")).is(":visible")
      return $.trim( @val() || '' )
    else
      return null


)($)

module.exports = QuestionView
