#!/bin/bash
echo "Adding git commit to displayed version"
COMMIT=$(git rev-parse --short HEAD)
sed -i "s/ - .*<\/div>/ - <a href='https:\/\/github.com\/ICTatRTI\/coconut-mobile\/commit\/$COMMIT'>$COMMIT<\/a><\/div>/" app/views/MenuView.coffee
sed -i "s/ - .*<\/div>/ - <a href='https:\/\/github.com\/ICTatRTI\/coconut-mobile\/commit\/$COMMIT'>$COMMIT<\/a><\/div>/" app/views/LoginView.coffee
echo "Browserifying, uglifying and then making bundle.js"
./node_modules/browserify/bin/cmd.js --verbose -t coffeeify --extension='.coffee' app/start.coffee -x moment -x jquery -x backbone -x pouchdb-core -x pouchdb-adapter-http -x pouchdb-mapreduce -x pouchdb-upsert -x underscore -x tabulator-tables | npx terser > bundle.js

echo "Minifying bundle-css.min.css"
./bundleCss.sh
echo "Minifying bundle-libraries.min.js"
./bundleJsLibraries.sh
workbox generateSW workbox-config.js
echo "Rsyncing to cloud"
rsync --verbose  --copy-links --recursive --exclude=node_modules ./ mobile.cococloud.co:/var/www/mobile.cococloud.co/ | grep total
# No longer use couch for serving the app so this isn't required
#couchapp push --no-atomic cococloud  
