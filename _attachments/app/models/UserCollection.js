var UserCollection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

UserCollection = (function(_super) {
  __extends(UserCollection, _super);

  function UserCollection() {
    return UserCollection.__super__.constructor.apply(this, arguments);
  }

  UserCollection.prototype.model = User;

  UserCollection.prototype.pouch = {
    options: {
      query: {
        include_docs: true,
        fun: "users"
      }
    }
  };

  UserCollection.prototype.parse = function(response) {
    return _(response.rows).pluck("doc");
  };

  UserCollection.prototype.district = function(userId) {
    if (!userId.match(/^user\./)) {
      userId = "user." + userId;
    }
    return this.get(userId).get("district");
  };

  return UserCollection;

})(Backbone.Collection);

UserCollection.load = function(options) {
  var designDocs, finished;
  Coconut.users = new UserCollection();
  designDocs = {
    users: function(doc) {
      if (doc.collection && doc.collection === "user") {
        return emit(doc._id, null);
      }
    },
    usersByDistrict: function(doc) {
      if (doc.collection && doc.collection === "user") {
        return emit(doc.district, [doc.name, doc._id.substring(5)]);
      }
    }
  };
  finished = _.after(_(designDocs).size(), function() {
    return Coconut.users.fetch({
      success: function() {
        return options.success();
      }
    });
  });
  return _(designDocs).each(function(designDoc, name) {
    designDoc = Utils.createDesignDoc(name, designDoc);
    return Utils.addOrUpdateDesignDoc(designDoc, {
      success: function() {
        return finished();
      }
    });
  });
};
