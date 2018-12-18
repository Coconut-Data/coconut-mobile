#!/bin/sh
cat css/fonts.css css/materialdesignicons.min.css node_modules/material-design-lite/material.css css/override_mdl.css css/styles.css css/modal-dialog.css node_modules/datatables/media/css/jquery.dataTables.min.css css/datatables.min.css | npx uglifycss > css/bundle-css.min.css
