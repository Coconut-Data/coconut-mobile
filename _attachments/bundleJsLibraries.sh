#!/bin/sh
cat ./node_modules/material-design-lite/material.min.js ./js-libraries/mdl-select.js ./js-libraries/coffee-script.js ./js-libraries/datatables.min.js | npx terser > bundle-libraries.min.js

