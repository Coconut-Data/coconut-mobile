_ = require 'underscore'
#CoffeeScript = require 'coffee-script'
Coconut = require './Coconut'

Utils = {}
Utils.addOrUpdateDesignDoc = (designDoc,options) ->
  name = designDoc._id.replace(/^_design\//,"")

  Coconut.database.get "_design/#{name}", (error,result) ->
    # Check if it already exists and is the same
    if result?.views?[name]?.map is designDoc.views[name].map
      options.success()
    else
      console.log "Updating design doc for #{name}"
      if result? and result._rev
        designDoc._rev = result._rev
      Coconut.database.put(designDoc).then ->
        options.success()
      .catch (error) ->
        console.log "Error. Current Result:"
        console.log result

        #Coconut.database.get "_design/#{name}", (error,result) ->
        #  console.log "GETTING AGAIN"
        #  console.log result

        console.log error
        console.log "^^^^^ Error updating designDoc for #{name}:"
        console.log designDoc

Utils.createDesignDoc = (name, mapFunction) ->
  # Allows coffeescript string to get compiled into functions for extra dynamic-ness - use heredocs """
  if not _.isFunction(mapFunction)
    mapFunction = CoffeeScript.compile(mapFunction, bare:on)
  else
    mapFunction = mapFunction.toString()

  ddoc = {
    _id: '_design/' + name,
    views: {}
  }
  ddoc.views[name] = {
    map: mapFunction
  }
  return ddoc

module.exports = Utils
