var Sync,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Sync = (function(_super) {
  __extends(Sync, _super);

  function Sync() {
    this.replicateApplicationDocs = __bind(this.replicateApplicationDocs, this);
    this.getFromCloud = __bind(this.getFromCloud, this);
    this.log = __bind(this.log, this);
    this.sendToCloud = __bind(this.sendToCloud, this);
    this.checkForInternet = __bind(this.checkForInternet, this);
    this.last_get_time = __bind(this.last_get_time, this);
    this.was_last_get_successful = __bind(this.was_last_get_successful, this);
    this.last_send_time = __bind(this.last_send_time, this);
    this.was_last_send_successful = __bind(this.was_last_send_successful, this);
    this.last_send = __bind(this.last_send, this);
    return Sync.__super__.constructor.apply(this, arguments);
  }

  Sync.prototype.initialize = function() {
    return this.set({
      _id: "SyncLog"
    });
  };

  Sync.prototype.target = function() {
    return Coconut.config.cloud_url();
  };

  Sync.prototype.last_send = function() {
    return this.get("last_send_result");
  };

  Sync.prototype.was_last_send_successful = function() {
    var last_send_data;
    if (this.get("last_send_error") === true) {
      return false;
    }
    last_send_data = this.last_send();
    if (last_send_data == null) {
      return false;
    }
    if ((last_send_data.no_changes != null) && last_send_data.no_changes === true) {
      return true;
    }
    return (last_send_data.docs_read === last_send_data.docs_written) && last_send_data.doc_write_failures === 0;
  };

  Sync.prototype.last_send_time = function() {
    var result;
    result = this.get("last_send_time");
    if (result) {
      return moment(this.get("last_send_time")).fromNow();
    } else {
      return "never";
    }
  };

  Sync.prototype.was_last_get_successful = function() {
    return this.get("last_get_success");
  };

  Sync.prototype.last_get_time = function() {
    var result;
    result = this.get("last_get_time");
    if (result) {
      return moment(this.get("last_get_time")).fromNow();
    } else {
      return "never";
    }
  };

  Sync.prototype.checkForInternet = function(options) {
    this.log("Checking for internet. (Is " + (Coconut.config.cloud_url()) + " is reachable?) Please wait.");
    return $.ajax({
      url: Coconut.config.cloud_url(),
      error: (function(_this) {
        return function(error) {
          _this.log("ERROR! " + (Coconut.config.cloud_url()) + " is not reachable. Do you have enough airtime? Are you on WIFI?  Either the internet is not working or the site is down: " + (JSON.stringify(error)));
          options.error();
          return _this.save({
            last_send_error: true
          });
        };
      })(this),
      success: (function(_this) {
        return function() {
          _this.log("" + (Coconut.config.cloud_url()) + " is reachable, so internet is available.");
          return options.success();
        };
      })(this)
    });
  };

  Sync.prototype.sendToCloud = function(options) {
    return this.fetch({
      error: (function(_this) {
        return function(error) {
          return _this.log("Unable to fetch Sync doc: " + (JSON.stringify(error)));
        };
      })(this),
      success: (function(_this) {
        return function() {
          return _this.checkForInternet({
            error: function(error) {
              return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
            },
            success: function() {
              _this.log("Creating list of all results on the tablet. Please wait.");
              return database.query("results", {}, function(error, result) {
                var resultIDs;
                if (error) {
                  _this.log("Could not retrieve list of results: " + (JSON.stringify(error)));
                  options.error();
                  return _this.save({
                    last_send_error: true
                  });
                } else {
                  _this.log("Synchronizing " + result.rows.length + " results. Please wait.");
                  resultIDs = _.pluck(result.rows, "id");
                  return database.replicate.to(Coconut.config.cloud_url_with_credentials(), {
                    doc_ids: resultIDs
                  }).on('complete', function(info) {
                    _this.log("Success! Send data finished: created, updated or deleted " + info.docs_written + " results on the server.");
                    _this.save({
                      last_send_result: result,
                      last_send_error: false,
                      last_send_time: new Date().getTime()
                    });
                    return options.success();
                  }).on('error', function(error) {
                    return options.error(error);
                  });
                }
              });
            }
          });
        };
      })(this)
    });
  };

  Sync.prototype.log = function(message) {
    return Coconut.debug(message);
  };

  Sync.prototype.getFromCloud = function(options) {
    return this.fetch({
      error: (function(_this) {
        return function(error) {
          return _this.log("Unable to fetch Sync doc: " + (JSON.stringify(error)));
        };
      })(this),
      success: (function(_this) {
        return function() {
          return _this.checkForInternet({
            error: function(error) {
              return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
            },
            success: function() {
              return _this.fetch({
                success: function() {
                  return _this.replicateApplicationDocs({
                    error: function(error) {
                      $.couch.logout();
                      _this.log("ERROR updating application: " + (JSON.stringify(error)));
                      _this.save({
                        last_get_success: false
                      });
                      return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
                    },
                    success: function() {
                      _this.save({
                        last_get_success: true,
                        last_get_time: new Date().getTime()
                      });
                      if (options != null) {
                        if (typeof options.success === "function") {
                          options.success();
                        }
                      }
                      return _.delay(function() {
                        return document.location.reload();
                      }, 5000);
                    }
                  });
                }
              });
            }
          });
        };
      })(this)
    });
  };

  Sync.prototype.replicateApplicationDocs = function(options) {
    return this.checkForInternet({
      error: function(error) {
        return options != null ? typeof options.error === "function" ? options.error(error) : void 0 : void 0;
      },
      success: (function(_this) {
        return function() {
          _this.log("Getting list of application documents to replicate");
          return $.ajax({
            url: "" + (Coconut.config.cloud_url()) + "/_design/coconut/_view/docIDsForUpdating",
            dataType: "json",
            include_docs: false,
            error: function(a, b, error) {
              return typeof options.error === "function" ? options.error(error) : void 0;
            },
            success: function(result) {
              var doc_ids;
              doc_ids = _.pluck(result.rows, "id");
              doc_ids = _(doc_ids).without("_design/coconut");
              _this.log("Updating " + doc_ids.length + " docs (users and forms). Please wait.");
              return database.replicate.from(Coconut.config.cloud_url_with_credentials(), {
                doc_ids: doc_ids
              }).on('change', function(info) {
                return $("#content").html("<h2> " + info.docs_written + " written out of " + doc_ids.length + " (" + (parseInt(100 * (info.docs_written / doc_ids.length))) + "%) </h2>");
              }).on('complete', function(info) {
                var resultData;
                resultData = _(info).chain().map(function(value, property) {
                  if (property.match(/^doc.*/)) {
                    return "" + property + ": " + value;
                  }
                }).compact().value();
                _this.log("Finished updating application documents: " + (JSON.stringify(resultData)));
                return typeof options.success === "function" ? options.success() : void 0;
              }).on('error', function(error) {
                _this.log("Error while updating application documents: " + (JSON.stringify(error)));
                return typeof options.error === "function" ? options.error(error) : void 0;
              });
            }
          });
        };
      })(this)
    });
  };

  return Sync;

})(Backbone.Model);
