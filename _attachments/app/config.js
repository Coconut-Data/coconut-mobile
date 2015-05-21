var L_PREFER_CANVAS, database, databaseName;

L_PREFER_CANVAS = true;

databaseName = "coconut";

database = PouchDB(databaseName);

Backbone.sync = BackbonePouch.sync({
  db: database,
  fetch: 'query'
});

Backbone.Model.prototype.idAttribute = '_id';
