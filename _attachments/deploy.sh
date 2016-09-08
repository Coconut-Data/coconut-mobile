echo "Browserifying, uglifying and then making bundle.js"
./node_modules/browserify/bin/cmd.js --verbose -t coffeeify --extension='.coffee' app/start.coffee | ./node_modules/uglify-js/bin/uglifyjs > bundle.js
echo "Updating version number in manifest.appcache"
perl -pe 's/^# VERSION ((\d+\.)*)(\d+)(.*)$/"# VERSION ".$1.($3+1).$4/e' -i manifest.appcache
echo "Pushing to cloud"
couchapp push --no-atomic cococloud
