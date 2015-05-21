var Utils;

Utils = {};

Utils.addOrUpdateDesignDoc = function(designDoc, options) {
  var name;
  name = designDoc._id.replace(/^_design\//, "");
  return database.get("_design/" + name, function(error, result) {
    var _ref, _ref1;
    if ((result != null ? (_ref = result.views) != null ? (_ref1 = _ref[name]) != null ? _ref1.map : void 0 : void 0 : void 0) === designDoc.views[name].map) {
      return options.success();
    } else {
      console.log("Updating design doc for " + name);
      if (result && result._rev) {
        designDoc._rev = result._rev;
      }
      return database.put(designDoc).then(function() {
        return options.success();
      });
    }
  });
};

Utils.createDesignDoc = function(name, mapFunction) {
  var ddoc;
  if (!_.isFunction(mapFunction)) {
    mapFunction = CoffeeScript.compile(mapFunction, {
      bare: true
    });
  } else {
    mapFunction = mapFunction.toString();
  }
  ddoc = {
    _id: '_design/' + name,
    views: {}
  };
  ddoc.views[name] = {
    map: mapFunction
  };
  return ddoc;
};
