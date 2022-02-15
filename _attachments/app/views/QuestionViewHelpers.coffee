bases = require 'bases'
underscored = require("underscore.string/underscored")


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

global.ResultOfQuestion = (name) ->
  if window.getValueCache[name]?
    window.getValueCache[name]
  else if window.getValueCache[slugify(name)]?
    window.getValueCache[slugify(name)]
  else
    null

global.PreviousQuestionResult =  ->
  window.previousQuestionResult

global.setValue = (targetLabel, value) ->
  @$("[name=#{slugify(targetLabel)}]").val(value)

global.setLabelText = (targetLabel, value) ->
  @$("[data-question-name=#{slugify(targetLabel)}] label").html(value)

global.showMessage = (questionTarget, html) ->
  messageElement = questionTarget.closest("div").children(".info-message").first()
  if messageElement.length is 0
    messageElement  = $("<div class='info-message'></div>")
    questionTarget.closest("div").append(messageElement[0])
  messageElement.html html
  messageElement.show()

global.warn = (questionTarget, text) ->
  messageElement = showMessage(questionTarget,text)
  messageElement.css("background-color", "yellow")
  _.delay =>
    messageElement.fadeOut()
    messageElement.css("background-color", "")
  , 5000

global.createSyncActionUnlessExists = (options) =>
  id = Coconut.questionView.result.data._id.replace(/result-/,"syncAction_#{options.type}-")
  existingSyncAction = await Coconut.database.get(id).catch (error) => Promise.resolve null
  unless existingSyncAction?
    Coconut.database.put
      _id: id
      action: options.action
      description: options.description

### EXAMPLE Sync Action Below ###
###
global.createNotifyEntomologySyncAction = (district, message) =>
  createSyncActionUnlessExists
    type: "notify-entomology"
    action: "notifyEntomology('#{district}','#{message}')"
    description: "Create notification for Entomology"

global.notifyEntomology = (district, message) =>
  entoDb = new PouchDB(Coconut.config.cloud_url_with_credentials_no_db()+"/entomology_surveillance")
  targetNumbers = await entoDb.allDocs
    startkey: "user"
    endkey: "user\uf000"
    include_docs: true
  .then (result) =>
    for row in result.rows
      if row.doc.districts?.includes district
        await sendSMS(row.doc.mobile,message)
###

# # # #

global.acronym = (idName) =>
  #create acronmym for ID
  acronym = ""
  for word in idName.split(" ")
    acronym += word[0].toUpperCase() unless ["ID","SPECIMEN","COLLECTION","INVESTIGATION"].includes word.toUpperCase()
  acronym

global.idPrefix = (idName)  =>
  "#{acronym(idName)}-#{Coconut.instanceId}"

global.highestIdBase32ForPrefix = (prefix) =>
  Coconut.database.allDocs
    startkey: "result-#{prefix}"
    endkey: "result-#{prefix}-\uf000"
    include_docs:false
  .then (result) =>
    highestIndexBase10 = 0
    for row in result.rows
      indexInBase32 = row.id.split("-").pop()
      indexInBase10 = bases.fromBase32(indexInBase32)
      if indexInBase10 > highestIndexBase10
        highestIndexBase10 = indexInBase10
    Promise.resolve(bases.toBase32(highestIndexBase10))

global.highestIdForPrefix = (prefix) =>
  Coconut.database.allDocs
    startkey: "result-#{prefix}"
    endkey: "result-#{prefix}-\uf000"
    include_docs:false
  .then (result) =>
    highestIndex = 0
    for row in result.rows
      index = parseInt(row.id.split("-").pop())
      if index > highestIndex
        highestIndex = index
    Promise.resolve(highestIndex)

global.setValueWithNextIdIfEmptyAndSetResultId = (idName) =>

  slugifiedIdName = slugify(idName)
  prefix = idPrefix(idName)
  element = document.querySelector("[name=#{slugifiedIdName}]")

  if element
    element.setAttribute("readonly", true)
    if element.value is ""
      highestIndex = await highestIdBase32ForPrefix(prefix)
      nextIndexBase10 = bases.fromBase32(highestIndex) + 1
      nextIndexBase32 = bases.toBase32(nextIndexBase10)
      idValue = "#{prefix}-#{nextIndexBase32}"
      element.value = idValue
      Coconut.questionView.result.data._id = "result-#{idValue}"

global.addIncrementingIdsForRepeatableQuestions = (parentIdQuestion, targetQuestion) =>
  _.delay =>
    slugifiedTargetId = slugify(targetQuestion)
    parentIdValue = ResultOfQuestion(parentIdQuestion)
    parentIdValueWithPrefixChanged = parentIdValue.replace(/.*?-/,"#{acronym(targetQuestion)}-")
    emptyIdElements = []
    highestIndexOnCurrentPage = "0"
    document.querySelectorAll("input").forEach (element) =>
      if element.getAttribute("name").match("].#{slugifiedTargetId}") # Look for the index character: ]
        if element.value is ""
          emptyIdElements.push element
        else
          elementIndex = element.value.split("-").pop() 
          if elementIndex > highestIndexOnCurrentPage
            highestIndexOnCurrentPage = elementIndex

    if emptyIdElements.length > 0
      highestIndex = highestIndexOnCurrentPage
      for element in emptyIdElements
        nextIndexBase10 = bases.fromBase32(highestIndex) + 1
        nextIndexBase32 = bases.toBase32(nextIndexBase10)
        element.value = "#{parentIdValueWithPrefixChanged}-#{nextIndexBase32}"
        highestIndex = nextIndexBase32
  , 500

