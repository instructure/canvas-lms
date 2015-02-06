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

    nameTooLong (a) {
      if (a.name.length > 30){
        return true 
      }
      else{
        return false
      }    
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
      return !a.please_ignore && (!a.due_at || assignmentUtils.notUniqueName(assignments, a) || assignmentUtils.nameTooLong(a))
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
    postGradesThroughCanvas (selected, assignments) {
      var url = "/api/v1/" + selected.type + "s/" + selected.id + "/post_grades/"
      var data = { assignments: _.map(assignments, (assignment) => assignment.id) }
      $.ajax(url, {
        type: 'POST',
        data: JSON.stringify(data),
        contentType: 'application/json; charset=utf-8',
        success: (msg) =>{
          if (msg.error){
            $.flashError(msg.error)
          }else{
            $.flashMessage(msg.message)
          }
        },
        error: (err) => {
          var msg = 'An error occurred posting grades for (' + selected.type + ' : ' + selected.id +'). '
          msg += "HTTP Error " + data.status + " : " + data.statusText
          $.flashError(msg)
        }
      })
    }

  };

  return assignmentUtils;
});
