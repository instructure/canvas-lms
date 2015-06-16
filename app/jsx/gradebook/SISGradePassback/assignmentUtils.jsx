/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'react',
  'jsx/shared/helpers/createStore'
], ($, _, createStore) => {

  assignmentUtils = {
    copyFromGradebook (assignment) {
      var a = _.pick(assignment, [
        "id",
        "name",
        "due_at",
        "needs_grading_count",
        "overrides"
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
      // This logic handles an assignment with multiple overrides
      // because #setGradeBookAssignments runs on load
      // it does not have a reference to what the currently viewed section is.
      // Due to this an assignment with 2 overrides (one valid, one invalid)
      // it will set original_errors to true. This logic checks the override
      // being viewed for that section. If the override is valid make
      // original error false so that the override is not shown. Vice versa
      // for the invalid override on the assignment.
      _.each(assignments, (a) => {
          if(a.overrideForThisSection != undefined && a.recentlyUpdated != undefined && a.recentlyUpdated == true && a.overrideForThisSection.due_at != null){a.original_error = false}
          else if(a.overrideForThisSection != undefined && a.recentlyUpdated != undefined && a.recentlyUpdated == false && a.overrideForThisSection.due_at == null){a.original_error = true}
      });
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
      ////Decided to ignore
      if(a.please_ignore) return false

      ////Not unique
      if(assignmentUtils.notUniqueName(assignments, a)) return true

      ////Name too long
      if(assignmentUtils.nameTooLong(a)) return true

      ////Non-override missing due_at
      var has_overrides = a.overrides != undefined ? a.overrides.length > 0 : false
      if(!has_overrides && !a.due_at) return true

      ////Override missing due_at
      var has_this_override = a.overrideForThisSection != undefined
      if(has_this_override && a.overrideForThisSection.due_at == null) return true

      ////Passes all tests, looks good.
      return false
    },

    suitableToPost(assignment) {
      return assignment.published && assignment.post_to_sis
    },

    saveAssignmentToCanvas (course_id, assignment) {
      // if the date on an override is being updated confirm by checking if the due_at is an object
      if(assignment.overrideForThisSection != undefined && typeof(assignment.overrideForThisSection.due_at) == "object") {
        var url = '/api/v1/courses/' + course_id + '/assignments/' + assignment.id + '/overrides/' + assignment.overrideForThisSection.id
        //sets up form data to allow a single override to be updated
        var fd = new FormData();
        fd.append( 'assignment_override[due_at]', assignment.overrideForThisSection.due_at.toISOString() )

        $.ajax(url, {
          type: 'PUT',
          data: fd,
          processData: false,
          contentType: false,
          error: (err) => {
            var msg = 'An error occurred saving assignment override, (' + assignment.overrideForThisSection.id + '). '
            msg += "HTTP Error " + data.status + " : " + data.statusText
            $.flashError(msg)
          }
        })
        // if there is a naming conflict on the assignment that has an override with a date
        // that was just set AND the naming conflict is fixed we must also update the assignment
        // to mock natural behavior to the user so that the naming conflict does not appear again
        url = '/api/v1/courses/' + course_id + '/assignments/' + assignment.id
        data = { assignment: {
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
      }
      else {
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
      }

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
