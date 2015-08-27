define([
  'react',
  'bower/reflux/dist/reflux',
  '../constants',
  'jquery',
  'underscore',
  'vendor/jquery.ba-tinypubsub'
], function (React, Reflux, GradebookConstants, $, _) {

  var SubmissionsActions = Reflux.createActions({
    load: { asyncResult: true },
    updateGrade: { asyncResult: true },
    updatedSubmissionsReceived: { asyncResult: false }
  });

  var splitUpIds = function(studentIds) {
    var splitIds, idSet;

    splitIds = [];

    while (studentIds.length > 0) {
      idSet = studentIds.splice(0, GradebookConstants.PAGINATION_COUNT);
      splitIds.push(idSet);
    }

    return splitIds;
  };

  SubmissionsActions.load.listen(function (studentIds) {
    var submissionsUrl, splitIds, deferreds, params;

    submissionsUrl = GradebookConstants.submissions_url;
    splitIds = splitUpIds(studentIds);

    deferreds = _.map(splitIds, function(idArray) {
      params = {};
      params.student_ids = idArray;
      params.response_fields = GradebookConstants.SUBMISSION_RESPONSE_FIELDS;
      return $.ajaxJSON(submissionsUrl, 'GET', params);
    });

    $.when.apply($, deferreds).then(function() {
      var results, allResults, responses;
      allResults = [];

      responses = arguments;
      if (responses.length > 1 && responses[1] === "success") {
        responses = [responses];
      }
      // Orders responses so they're in the same order as requested
      responses = _.map(deferreds, (deferred) =>
                        _.find(responses, function(result) {
                          var isDeferred = (result[2] === deferred);
                          return isDeferred;
                        }
                   ));

      for (var responseNumber = 0; responseNumber < responses.length; responseNumber++) {
        results = responses[responseNumber][0];
        allResults = allResults.concat(results);
      }

      this.completed(allResults);
    }.bind(this));
  });

  SubmissionsActions.updateGrade.listen(function (submission) {
    var url = GradebookConstants.change_grade_url
      .replace(':assignment', submission.assignmentId)
      .replace(':submission', submission.userId);

    $.ajaxJSON(url, 'PUT', { 'submission[posted_grade]': submission.postedGrade })
      .done((response) => this.completed(submission, response))
      .fail((jqxhr, textStatus, error) => this.failed(error));
  });

  $.subscribe('submissions_updated', function (updatedSubmissions) {
    if (updatedSubmissions.length > 0) {
      SubmissionsActions.updatedSubmissionsReceived(updatedSubmissions);
    }
  });

  return SubmissionsActions;
});
