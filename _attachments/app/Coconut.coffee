$ = require 'jquery'
PouchDB = require 'pouchdb'

# Need to make it global for crypto-pouch plugin to work...I think
window.PouchDB = PouchDB
window.$ = $
require 'crypto-pouch'

throw "Must define global.username before intializing Coconut and the database" unless global.username?

module.exports =
  {
    database: PouchDB global.username

    debug: (string) ->
      console.log string
      $("#log").append string + "<br/>"

    colors: {
      primary1: "rgb(63,81,181)"
      primary2: "rgb(48,63,159)"
      accent1: "rgb(230,33,90)"
      accent2: "rgb(194,24,91)"
    }
  }
