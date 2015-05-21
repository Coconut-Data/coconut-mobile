var ResultCollection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

ResultCollection = (function() {
  function ResultCollection() {
    this.fetch = __bind(this.fetch, this);
  }

  ResultCollection.prototype.fetch = function(options) {
    var fields, queryOptions;
    queryOptions = _.extend({
      include_docs: false,
      startkey: [options.question, options.isComplete === true],
      endkey: [options.question, options.isComplete === true, {}]
    }, options);
    fields = (Coconut.questions.find(function(question) {
      return question.id === options.question;
    })).summaryFieldKeys();
    return database.query("results", queryOptions, (function(_this) {
      return function(error, result) {
        _this.results = _(result.rows).map(function(row) {
          var returnVal;
          returnVal = _.object(fields, row.value);
          returnVal._id = row.id;
          return new Result(returnVal);
        });
        return options.success();
      };
    })(this));
  };

  ResultCollection.prototype.each = function(arg) {
    return _(this.results).each(arg);
  };

  ResultCollection.load = function(options) {
    return Coconut.questions.fetch({
      error: function(error) {
        return console.log("Error loading Coconut.questions: " + (JSON.stringify(error)));
      },
      success: function() {
        var designDocs, finished;
        designDocs = {
          results: "(doc) ->\n  if doc.collection is \"result\" and doc.question and (doc.complete or doc.complete is null) and doc.createdAt\n    summaryFields = (" + (Coconut.questions.map(function(question) {
            return "if doc.question is '" + question.id + "' then " + (JSON.stringify(question.summaryFieldKeys()));
          }).join(" else ")) + ")\n\n    summaryResults = []\n    for field in summaryFields\n      summaryResults.push doc[field]\n\n    emit([doc.question, doc.complete is \"true\", doc.createdAt], summaryResults)",
          resultsByQuestionNotCompleteNotTransferredOut: function(document) {
            if (document.collection === "result") {
              if (document.complete !== "true") {
                if (document.transferred != null) {
                  return emit(document.question, document.transferred[document.transferred.length - 1].to);
                } else {
                  return emit(document.question, null);
                }
              }
            }
          },
          rawNotificationsConvertedToCaseNotifications: function(document) {
            if (document.hf && document.hasCaseNotification) {
              return emit(document.date, null);
            }
          }
        };
        finished = _.after(_(designDocs).size(), function() {
          return options.success();
        });
        return _(designDocs).each(function(designDoc, name) {
          designDoc = Utils.createDesignDoc(name, designDoc);
          return Utils.addOrUpdateDesignDoc(designDoc, {
            success: function() {
              return finished();
            }
          });
        });
      }
    });
  };

  return ResultCollection;

})();
