var Config,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Config = (function(_super) {
  __extends(Config, _super);

  function Config() {
    this.cloud_url_no_http = __bind(this.cloud_url_no_http, this);
    this.cloud_database_name = __bind(this.cloud_database_name, this);
    this.fetch = __bind(this.fetch, this);
    return Config.__super__.constructor.apply(this, arguments);
  }

  Config.prototype.initialize = function() {
    return this.set({
      _id: "coconut.config"
    });
  };

  Config.prototype.fetch = function(options) {
    return database.get("coconut.config", (function(_this) {
      return function(error, result) {
        _this.set(result);
        return database.get("coconut.config.local", function(error, result) {
          Coconut.config.local = new Backbone.Model();
          Coconut.config.local.set(result);
          return typeof options.success === "function" ? options.success() : void 0;
        });
      };
    })(this));
  };

  Config.prototype.title = function() {
    return this.get("title") || "Coconut";
  };

  Config.prototype.database_name = function() {
    return database._db_name;
  };

  Config.prototype.cloud_database_name = function() {
    return this.get("cloud_database_name") || this.database_name();
  };

  Config.prototype.cloud_url = function() {
    return "http://" + (this.cloud_url_no_http()) + "/" + (this.cloud_database_name());
  };

  Config.prototype.cloud_url_with_credentials = function() {
    return "http://" + (this.get("cloud_credentials")) + "@" + (this.cloud_url_no_http()) + "/" + (this.cloud_database_name());
  };

  Config.prototype.cloud_log_url_with_credentials = function() {
    return "http://" + (this.get("cloud_credentials")) + "@" + (this.cloud_url_no_http()) + "/" + (this.cloud_database_name()) + "-log";
  };

  Config.prototype.cloud_url_no_http = function() {
    return this.get("cloud").replace(/http:\/\//, "");
  };

  return Config;

})(Backbone.Model);
