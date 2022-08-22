#!/bin/bash
echo "Did you kill the npm run start process, otherwise you will get a corrupt bundle.js!"
read justareminder

echo "Browserifying, uglifying and then making bundle.js"
./node_modules/browserify/bin/cmd.js --verbose -t coffeeify --extension='.coffee' app/start.coffee -x moment -x jquery -x backbone -x pouchdb-core -x pouchdb-adapter-http -x pouchdb-find -x pouchdb-mapreduce -x pouchdb-replication -x pouchdb-upsert -x underscore -x tabulator-tables > bundle.js
ls -al bundle.js

echo "Minifying bundle-css.min.css"
./bundleCss.sh
echo "Minifying bundle-libraries.min.js"
./bundleJsLibraries.sh
echo "Minifying vendor.min.js"
./bundleVendor.sh
echo "Generating workbook sw"
workbox generateSW workbox-config.js
