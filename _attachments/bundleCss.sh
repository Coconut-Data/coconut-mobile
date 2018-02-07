#!/bin/sh
cat css/fonts.css css/materialdesignicons.min.css css/material.css css/override_mdl.css css/styles.css css/modal-dialog.css css/jquery.dataTables.min.css | ./node_modules/uglifycss/uglifycss > css/bundle-css.min.css
