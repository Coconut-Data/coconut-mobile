gulp = require 'gulp'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
cssmin = require 'gulp-cssmin'
shell = require 'gulp-shell'
gutil = require 'gulp-util'
debug = require 'gulp-debug'


gulp.task 'coffee', ->
  gulp.src ["./app/**/*.coffee","./app/*.coffee"]
  .pipe coffee
    bare: true
  .pipe gulp.dest "./app/"

gulp.task 'css', ->
  css = [
    "jquery.mobile-1.1.0.min.css"
    "leaflet.css"
    "jquery.dataTables.min.css"
    "dataTables.tableTools.min.css"
  ]
  css = ("./css/#{file}" for file in css)

  gulp.src css
    .pipe cssmin()
    .pipe concat "style.min.css"
    .pipe gulp.dest "./css/"

gulp.task 'libs', ->
  libs = [
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
  ]

  libs = ("./js-libraries/#{file}" for file in libs)

  gulp.src libs
    .pipe uglify()
    .pipe concat "libs.min.js"
    .pipe gulp.dest "./js/"

gulp.task 'app', ->
  app = [
    'utils.js'
    'config.js'
    'models/Case.js'
    'models/Config.js'
    'models/Help.js'
    'models/LocalConfig.js'
    'models/Question.js'
    'models/QuestionCollection.js'
    'models/Result.js'
    'models/ResultCollection.js'
    'models/Sync.js'
    'models/User.js'
    'models/UserCollection.js'
    'views/CsvView.js'
    'views/HelpView.js'
    'views/LocalConfigView.js'
    'views/LoginView.js'
    'views/MenuView.js'
    'views/QuestionView.js'
    'views/ResultsView.js'
    'views/SyncView.js'
    'views/UsersView.js'
    'app.js'
  ]

  app = ("./app/#{file}" for file in app)
    
  gulp.src app
#  .pipe debug()
  .pipe uglify()
  .pipe concat "app.min.js"
  .pipe gulp.dest "./js/"

gulp.task 'default', [
  'coffee'
  'libs'
  'css'
  'app'
]

#gulp.watch "#{base_dir}/*.html", ['app']
#gulp.watch ["#{base_dir}/app/**/*.coffee","#{base_dir}/app/*.coffee"], ['coffee','app']

