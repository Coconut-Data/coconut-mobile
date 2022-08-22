#!/bin/sh
npx browserify  -r moment -r jquery -r backbone -r pouchdb-core -r pouchdb-adapter-http -r pouchdb-mapreduce -r pouchdb-replication -r pouchdb-upsert -r pouchdb-find -r underscore -r tabulator-tables | npx terser > vendor.min.js

