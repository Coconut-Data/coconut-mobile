$ = require 'jquery'
PouchDB = require 'pouchdb'


module.exports = {
  database: PouchDB "coconut"

  debug: (string) ->
    console.log string
    $("#log").append string + "<br/>"
}
