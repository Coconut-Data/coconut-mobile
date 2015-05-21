var QuestionCollection,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

QuestionCollection = (function(_super) {
  __extends(QuestionCollection, _super);

  function QuestionCollection() {
    return QuestionCollection.__super__.constructor.apply(this, arguments);
  }

  QuestionCollection.prototype.model = Question;

  QuestionCollection.prototype.pouch = {
    options: {
      query: {
        include_docs: true,
        fun: "questions"
      }
    }
  };

  QuestionCollection.prototype.parse = function(response) {
    return _(response.rows).pluck("doc");
  };

  QuestionCollection.load = function(options) {
    var questionsDesignDoc;
    Coconut.questions = new QuestionCollection();
    questionsDesignDoc = Utils.createDesignDoc("questions", function(doc) {
      if (doc.collection && doc.collection === "question") {
        return emit(doc._id, doc.resultSummaryFields);
      }
    });
    return Utils.addOrUpdateDesignDoc(questionsDesignDoc, {
      success: function() {
        return Coconut.questions.fetch({
          success: function() {
            return options.success();
          }
        });
      }
    });
  };

  return QuestionCollection;

})(Backbone.Collection);
