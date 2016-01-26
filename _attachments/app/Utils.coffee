_ = require 'underscore'
#CoffeeScript = require 'coffee-script' - this is loaded in index.html

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

        console.log error
        console.log "^^^^^ Error updating designDoc for #{name}:"
        console.log designDoc

        if confirm("Database Error. Do you want to reset the database?")
          Coconut.database.destroy().then ->

            cloudUrl = Coconut.config.get("cloud")
            appName = Coconut.config.get("cloud_database_name")
            [username,password] = Coconut.config.get("cloud_credentials").split(":")
            Coconut.router.navigate("",true)

            document.location = document.location.origin + document.location.pathname + "?cloudUrl=#{cloudUrl}&appName=#{appName}&username=#{username}&password=#{password}&showPrompt=yes"
          

Utils.createDesignDoc = (name, mapFunction) ->
  # Allows coffeescript string to get compiled into functions. For extra dynamic-ness - use heredocs """ (see ResultCollection)
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
