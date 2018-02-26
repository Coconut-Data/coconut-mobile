#!/bin/bash
echo "Adding git commit to displayed version"
COMMIT=$(git rev-parse --short HEAD);sed -i "s/ - .*<\/div>/ - <a href='https:\/\/github.com\/ICTatRTI\/coconut-mobile\/commit\/$COMMIT'>$COMMIT<\/a><\/div>/" app/views/MenuView.coffee
echo "Browserifying, uglifying and then making bundle.js"
./node_modules/browserify/bin/cmd.js --verbose -t coffeeify --extension='.coffee' app/start.coffee | ./node_modules/uglify-js/bin/uglifyjs > bundle.js
echo "Minifying bundle-css.min.css"
./bundleCss.sh
echo "Minifying bundle-libraries.min.js"
./bundleJsLibraries.sh
echo "Updating version number in manifest.appcache"
perl -pe 's/^# VERSION ((\d+\.)*)(\d+)(.*)$/"# VERSION ".$1.($3+1).$4/e' -i manifest.appcache
echo "Pushing to cloud"
rsync --progress --recursive --exclude=node_modules ./ cococloud.co:/var/www/mobile/
#couchapp push --no-atomic cococloud
