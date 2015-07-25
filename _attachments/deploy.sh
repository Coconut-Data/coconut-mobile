browserify --verbose -t coffeeify --extension='.coffee' app/start.coffee | uglifyjs > bundle.js
perl -pe 's/^# VERSION ((\d+\.)*)(\d+)(.*)$/"# VERSION ".$1.($3+1).$4/e' -i manifest.appcache
couchapp push --no-atomic cococloud
