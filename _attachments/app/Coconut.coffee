$ = require 'jquery'
PouchDB = require 'pouchdb'

# Need to make it global for crypto-pouch plugin to work...I think
window.PouchDB = PouchDB
require 'crypto-pouch'

throw "Must define global.username before intializing Coconut and the database" unless global.username?

module.exports =
  {
    database: PouchDB global.username

    debug: (string) ->
      console.log string
      $("#log").append string + "<br/>"
  }
