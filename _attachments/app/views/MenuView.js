var MenuView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

MenuView = (function(_super) {
  __extends(MenuView, _super);

  function MenuView() {
    this.render = __bind(this.render, this);
    return MenuView.__super__.constructor.apply(this, arguments);
  }

  MenuView.prototype.el = '.question-buttons';

  MenuView.prototype.events = {
    "change": "render"
  };

  MenuView.prototype.render = function() {
    this.$el.html("<div id='navbar' data-role='navbar'> <ul></ul> </div>");
    return Coconut.questions.fetch({
      success: (function(_this) {
        return function() {
          _this.$el.find("ul").html(Coconut.questions.map(function(question, index) {
            return "<li><a id='menu-" + index + "' href='#show/results/" + (escape(question.id)) + "'><h2>" + question.id + "<div id='menu-partial-amount'></div></h2></a></li>";
          }).join(" "));
          $(".question-buttons").navbar();
          return _this.update();
        };
      })(this)
    });
  };

  MenuView.prototype.update = function() {
    if (Coconut.config.local.get("mode") === "mobile") {
      User.isAuthenticated({
        success: function() {
          return Coconut.questions.each((function(_this) {
            return function(question, index) {
              return database.query("resultsByQuestionNotCompleteNotTransferredOut", {
                key: question.id,
                include_docs: false
              }, function(error, result) {
                var total;
                if (error) {
                  console.log(error);
                }
                total = 0;
                _(result.rows).each(function(row) {
                  var transferredTo;
                  transferredTo = row.value;
                  if (transferredTo != null) {
                    if (User.currentUser.id === transferredTo) {
                      return total += 1;
                    }
                  } else {
                    return total += 1;
                  }
                });
                return $("#menu-" + index + " #menu-partial-amount").html(total);
              });
            };
          })(this));
        }
      });
    }
    return database.get("version", function(error, result) {
      if (error) {
        return $("#version").html("-");
      } else {
        return $("#version").html(result.version);
      }
    });
  };

  return MenuView;

})(Backbone.View);
