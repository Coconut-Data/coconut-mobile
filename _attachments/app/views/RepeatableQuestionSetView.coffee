class RepeatableQuestionSetView extends Backbone.View
  constructor: (options) ->
    super()

    @questionViews = {}
    @targetRepeatableField = options.targetRepeatableField
    @questionSet = options.questionSet
    @disableTarget = options.disableTarget or true
    @prefix = Math.floor(Math.random()*1000)
    @setElement $("
      <div style='padding-left:40px' class='repeatableQuestionSet' id=''>
      </div>
    ")
    @targetRepeatableField.after @el
    _(@targetRepeatableField.val()?.split(/,/)).each (dataValue) =>
      # TODO parse concatenated json data from field into theUI
      # return if dataValue.replace(/ *:* */,"") is ""
      # [locationName, entryPoint] = location.split(/: /)
      # locationSelector = @addRepeatableItem()
      # locationSelector.find("[name=travelLocationName]").val locationName
      # locationSelector.find("[value='#{entryPoint}']").prop('checked',true)
    @$el.append @addRepeatableQuestionSetButton() if @$('.addRepeatableItem').length is 0
    @targetRepeatableField.prop('disabled', @disableTarget)

  events:
    "click button.addRepeatableItem": "addRepeatableItem"
    "click button.removeRepeatableItem": "removeRepeatableItem"

  addRepeatableQuestionSetButton: => "
    <button type='button' style='' class='addRepeatableItem mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>
      Add #{@questionSet.label()}
    </button>
  "

  removeRepeatableQuestionSetButton: => "
    <button type='button' style='margin-left:250px;' class='removeRepeatableItem mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>
      Remove #{@questionSet.label()}
    </button>
  "

  removeRepeatableItem: (event) =>
    repeatableItemToRemove = $(event.target).closest(".repeatableItem")
    delete @questionViews[repeatableItemToRemove.attr("id")]
    repeatableItemToRemove.remove()
    if @$('.addRepeatableItem').length is 0
      @$el.append @addRepeatableQuestionSetButton() if @$('.addRepeatableItem').length is 0
    @updateTargetRepeatableField()

  addRepeatableItem: (event) =>
    $(event.target).closest("button.addRepeatableItem").remove() if event # Remove the addRepeatableItem button that was clicked
    @prefix+=1
    @repeatableItemNumber = if @repeatableItemNumber? then @repeatableItemNumber+1 else 0

    repeatableQuestionSet = @targetRepeatableField.siblings("div.repeatableQuestionSet")

    repeatableItem= $("<div class='repeatableItem' id='#{@prefix}'/>")

    questionView = new QuestionView()
    questionView.setElement(repeatableItem)
    questionView.readonly = false
    questionView.isRepeatableQuestionSet = true
    questionView.namePrefix = "#{@questionSet.label()}[#{@repeatableItemNumber}]."
    questionView.model = @questionSet
    questionView.render()
    #@listenTo questionView, "update", (result) =>
    #  console.log "UPDATE"
    #  console.log result
    #@questionViews[@prefix] = questionView

    repeatableItem.find(".content_title").append(" ##{@repeatableItemNumber+1}")
    repeatableItem.append "
      <div style='margin-top:100px'>
        #{@addRepeatableQuestionSetButton()}
        #{@removeRepeatableQuestionSetButton()}
      </div>
    "

    repeatableQuestionSet.append repeatableItem
    componentHandler.upgradeDom()

    return repeatableItem

  updateTargetRepeatableField: =>
    @targetRepeatableField.val(
      val = _.chain(@$el.find(".repeatableItem")).map (location) =>
        locationName = $(location).find("input[name='travelLocationName']").val()
        entryMethod = $(location).find("input.entrymethod:checked").val() or ""
        if locationName
          if @$el.find("button.addRepeatableItem").length is 0
            @$el.append @addRepeatableQuestionSetButton()
          "#{locationName}: #{entryMethod}"
        else
          null
      .compact().join(", ").value()
    ).change() # Needed to trigger change event
    @targetRepeatableField.closest("div.mdl-textfield").addClass "is-dirty"

module.exports = RepeatableQuestionSetView
