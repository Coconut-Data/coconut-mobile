#!/bin/sh
cat ./js-libraries/material.min.js ./js-libraries/mdl-select.js ./js-libraries/coffee-script.js  | ./node_modules/uglify-js/bin/uglifyjs > bundle-libraries.min.js

