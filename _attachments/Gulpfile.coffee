gulp = require 'gulp'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
cssmin = require 'gulp-cssmin'
shell = require 'gulp-shell'
gutil = require 'gulp-util'
debug = require 'gulp-debug'
sourcemaps = require 'gulp-sourcemaps'
watch = require 'gulp-watch'
livereload = require 'gulp-livereload'

# CONFIGURATION #

js_library_file = "libs.min.js"
compiled_js_directory = "./js/"
app_file = "app.min.js"
css_file = "style.min.css"
css_file_dir = "./css/"

css_files = ("./css/#{file}" for file in [
    "jquery.mobile-1.1.0.min.css"
    "leaflet.css"
    "jquery.dataTables.min.css"
    "dataTables.tableTools.min.css"
  ])


js_library_files = ("./js-libraries/#{file}" for file in [
    "appcache-nanny.js"
    "jquery-2.1.0.min.js"
    "jquery-migrate-1.2.1.min.js"
    "lodash.underscore.js"
    "backbone-min.js"
    "jquery.couch.js"
    "pouchdb-3.3.1.min.js"
    "backbone-pouch.js"
    "jqm-config.js"
    "jquery.mobile-1.1.0.min.js"
    "jquery.mobile.datebox.min.js"
    "jqm.autoComplete.min-1.3.js"
    "coffee-script.js"
    "typeahead.min.js"
    "form2js.js"
    "js2form.js"
    "jquery.toObject.js"
    "inflection.js"
    "jquery.dateFormat-1.0.js"
    "jquery.dataTables.min.js"
    "datatables.tableTools.min.js"
    "moment.min.js"
    "jquery.cookie.js"
    "base64.js"
    "sha1.js"
    "markdown.min.js"
    "geo.js"
  ])

app_files = ("./app/#{file}" for file in [
    'utils.coffee'
    'config.coffee'
    'models/Case.coffee'
    'models/Config.coffee'
    'models/Help.coffee'
    'models/LocalConfig.coffee'
    'models/Question.coffee'
    'models/QuestionCollection.coffee'
    'models/Result.coffee'
    'models/ResultCollection.coffee'
    'models/Sync.coffee'
    'models/User.coffee'
    'models/UserCollection.coffee'
    'views/CsvView.coffee'
    'views/HelpView.coffee'
    'views/LocalConfigView.coffee'
    'views/LoginView.coffee'
    'views/MenuView.coffee'
    'views/QuestionView.coffee'
    'views/ResultsView.coffee'
    'views/SyncView.coffee'
    'views/UsersView.coffee'
    'app.coffee'
  ])

compile_and_concat = () ->
  gutil.log "Combining javascript libraries into #{js_library_file}"
  gulp.src js_library_files
    .pipe sourcemaps.init()
    .pipe concat js_library_file
    .pipe sourcemaps.write()
    .pipe gulp.dest compiled_js_directory

  gutil.log "Compiling coffeescript and combining into #{app_file}"
  gulp.src app_files
    .pipe sourcemaps.init()
    .pipe coffee
      bare: true
    .on 'error', gutil.log
    .pipe concat app_file
    .pipe sourcemaps.write()
    .pipe gulp.dest compiled_js_directory

  gutil.log "Combining css into #{css_file}"
  gulp.src css_files
    .pipe concat css_file
    .pipe gulp.dest css_file_dir

couchapp_push = (destination = "default") ->
  gutil.log "Pushing to couchdb"
  gulp.src("").pipe shell(["couchapp push #{destination}"])

minify = () ->
  for file in [js_library_file, app_file]
    gutil.log "uglifying: #{file}"
    gulp.src "#{compiled_js_directory}#{file}"
      .pipe uglify()
      .pipe concat file
      .pipe gulp.dest compiled_js_directory

  # Note that cssmin doesn't reduce file size much
  gutil.log "cssmin'ing #{css_file_dir}#{css_file}"
  gulp.src "#{css_file_dir}#{css_file}"
    .pipe cssmin()
    .pipe concat css_file
    .pipe gulp.dest css_file_dir

develop = () ->
  compile_and_concat()
  couchapp_push()
  gutil.log "Refreshing browser"
# TODO write gulp-couchapp to push so we don't have to guess here
  setTimeout livereload.reload, 3000

gulp.task 'minify', ->
  compile_and_concat()
  minify()

gulp.task 'deploy', ->
  compile_and_concat()
  minify()
  couchapp_push("cloud")

gulp.task 'develop', ->
  compile_and_concat()
  couchapp_push()
  livereload.listen
    start: true
  gulp.watch app_files.concat(js_library_files).concat(css_files), develop

gulp.task 'default', ->
  compile_and_concat()
  minify()
