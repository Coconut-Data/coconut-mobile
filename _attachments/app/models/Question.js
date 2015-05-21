var Question,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Question = (function(_super) {
  __extends(Question, _super);

  function Question() {
    this.summaryFieldNames = __bind(this.summaryFieldNames, this);
    this.resultSummaryFields = __bind(this.resultSummaryFields, this);
    return Question.__super__.constructor.apply(this, arguments);
  }

  Question.prototype.initialize = function() {
    return this.set({
      collection: "result"
    });
  };

  Question.prototype.type = function() {
    return this.get("type");
  };

  Question.prototype.label = function() {
    if (this.get("label") != null) {
      return this.get("label");
    } else {
      return this.get("id");
    }
  };

  Question.prototype.safeLabel = function() {
    return this.label().replace(/[^a-zA-Z0-9 -]/g, "").replace(/[ -]/g, "");
  };

  Question.prototype.repeatable = function() {
    return this.get("repeatable");
  };

  Question.prototype.questions = function() {
    return this.get("questions");
  };

  Question.prototype.value = function() {
    if (this.get("value") != null) {
      return this.get("value");
    } else {
      return "";
    }
  };

  Question.prototype.required = function() {
    if (this.get("required") != null) {
      return this.get("required");
    } else {
      return "true";
    }
  };

  Question.prototype.validation = function() {
    if (this.get("validation") != null) {
      return this.get("validation");
    } else {
      return null;
    }
  };

  Question.prototype.skipLogic = function() {
    return this.get("skip_logic") || "";
  };

  Question.prototype.actionOnChange = function() {
    return this.get("action_on_change") || "";
  };

  Question.prototype.attributeSafeText = function() {
    var returnVal;
    returnVal = this.get("label") != null ? this.get("label") : this.get("id");
    return returnVal.replace(/[^a-zA-Z0-9]/g, "");
  };

  Question.prototype.url = "/question";

  Question.prototype.set = function(attributes) {
    if (attributes.questions != null) {
      attributes.questions = _.map(attributes.questions, function(question) {
        return new Question(question);
      });
    }
    if (attributes.id != null) {
      attributes._id = attributes.id;
    }
    return Question.__super__.set.call(this, attributes);
  };

  Question.prototype.loadFromDesigner = function(domNode) {
    var attribute, property, result, _i, _len, _ref;
    result = Question.fromDomNode(domNode);
    if (result.length === 1) {
      result = result[0];
      this.set({
        id: result.id
      });
      _ref = ["label", "type", "repeatable", "required", "validation"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        property = _ref[_i];
        attribute = {};
        attribute[property] = result.get(property);
        this.set(attribute);
      }
      return this.set({
        questions: result.questions()
      });
    } else {
      throw "More than one root node";
    }
  };

  Question.prototype.resultSummaryFields = function() {
    var numberOfFields, resultSummaryFields, returnValue, _i, _results;
    resultSummaryFields = this.get("resultSummaryFields");
    if (resultSummaryFields) {
      return resultSummaryFields;
    } else {
      numberOfFields = Math.min(2, this.questions().length - 1);
      returnValue = {};
      _.each((function() {
        _results = [];
        for (var _i = 0; 0 <= numberOfFields ? _i <= numberOfFields : _i >= numberOfFields; 0 <= numberOfFields ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this), (function(_this) {
        return function(index) {
          var _ref;
          return returnValue[(_ref = _this.questions()[index]) != null ? _ref.label() : void 0] = "on";
        };
      })(this));
      return returnValue;
    }
  };

  Question.prototype.summaryFieldNames = function() {
    return _.keys(this.resultSummaryFields());
  };

  Question.prototype.summaryFieldKeys = function() {
    return _.map(this.summaryFieldNames(), function(key) {
      return key.replace(/[^a-zA-Z0-9 -]/g, "").replace(/[ -]/g, "");
    });
  };

  return Question;

})(Backbone.Model);

Question.fromDomNode = function(domNode) {
  return _(domNode).chain().map((function(_this) {
    return function(question) {
      var attribute, id, property, propertyValue, result, _i, _len, _ref;
      question = $(question);
      id = question.attr("id");
      if (question.children("#rootQuestionName").length > 0) {
        id = question.children("#rootQuestionName").val();
      }
      if (!id) {
        return;
      }
      result = new Question;
      result.set({
        id: id
      });
      _ref = ["label", "type", "repeatable", "select-options", "radio-options", "autocomplete-options", "validation", "required", "action_on_questions_loaded", "skip_logic", "action_on_change", "image-path", "image-style"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        property = _ref[_i];
        attribute = {};
        propertyValue = question.find("#" + property + "-" + id).val();
        if (property === "required") {
          propertyValue = String(question.find("#" + property + "-" + id).is(":checked"));
        }
        if (propertyValue != null) {
          attribute[property] = propertyValue;
          result.set(attribute);
        }
      }
      result.set({
        safeLabel: result.safeLabel()
      });
      if (question.find(".question-definition").length > 0) {
        result.set({
          questions: Question.fromDomNode(question.children(".question-definition"))
        });
      }
      return result;
    };
  })(this)).compact().value();
};
