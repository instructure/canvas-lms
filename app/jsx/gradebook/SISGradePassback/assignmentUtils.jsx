/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'jsx/shared/helpers/createStore'
], ($, _, createStore) => {

  assignmentUtils = {
    copyFromGradebook (assignment) {
      var a = _.pick(assignment, [
        "id",
        "name",
        "due_at",
        "needs_grading_count"
      ])
      a.please_ignore = false
      a.original_error = false
      return a
    },

    namesMatch (a, b) {
      return a.name === b.name && a !== b
    },

    notUniqueName (assignments, a) {
      return assignments.some(_.partial(assignmentUtils.namesMatch, a))
    },

    withOriginalErrors (assignments) {
      return _.filter(assignments, (a) => a.original_error)
    },

    withOriginalErrorsNotIgnored (assignments) {
      return _.filter(assignments, (a) => a.original_error && !a.please_ignore)
    },

    withErrors (assignments) {
      return _.filter(assignments, (a) => assignmentUtils.hasError(assignments, a))
    },

    notIgnored (assignments) {
      return _.filter(assignments, (a) => !a.please_ignore)
    },

    needsGrading (assignments) {
      return _.filter(assignments, (a) => a.needs_grading_count > 0)
    },

    hasError (assignments, a) {
      return !a.please_ignore && (!a.due_at || assignmentUtils.notUniqueName(assignments, a))
    },

    suitableToPost(assignment) {
      return assignment.published && assignment.post_to_sis
    },

    saveAssignmentToCanvas (course_id, assignment) {
      var url = '/api/v1/courses/' + course_id + '/assignments/' + assignment.id
      var data = { assignment: {
        name: assignment.name,
        due_at: assignment.due_at
      }}
      $.ajax(url, {
        type: 'PUT',
        data: JSON.stringify(data),
        contentType: 'application/json; charset=utf-8',
        error: (err) => {
          var msg = 'An error occurred saving assignment (' + assignment.id + '). '
          msg += "HTTP Error " + data.status + " : " + data.statusText
          $.flashError(msg)
        }
      })
    },

    // Sends a post-grades request to Canvas that is then forwarded to SIS App.
    // Expects a list of assignments that will later be queried for grades via
    // SIS App's workers
    postGradesThroughCanvas (assignments) {
      console.error("not yet implemented: postAssignmentsThroughCanvas")
      console.log('assignments', assignments)
    }

  };

  return assignmentUtils;
});
