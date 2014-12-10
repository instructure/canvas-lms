/** @jsx React.DOM */

define([
  'jquery',
  'underscore',
  'i18n!modules',
  'jsx/shared/helpers/createStore',
  'jsx/gradebook/SISGradePassback/assignmentUtils',
], ($, _, I18n, createStore, assignmentUtils) => {

  var PostGradesStore = (state) => {
    var store = $.extend(createStore(state), {

      reset () {
        var assignments = this.getState().assignments
        _.each(assignments, (a) => a.please_ignore = false)
        this.setState({
          assignments: assignments,
          pleaseShowNeedsGradingPage: false
        })
      },

      isEnabled () {
        return this.getState().selected.sis_id
      },

      hasAssignments () {
        var assignments = this.getState().assignments
        if (assignments != undefined && assignments.length > 0) {
          return true
        } else {
          return false
        }
      },

      getSISSectionId (section_id) {
        var sections = this.getState().sections
        return (sections && sections[section_id]) ?
          sections[section_id].sis_section_id :
          null;
      },

      setGradeBookAssignments (gradebookAssignments) {
        var assignments = []
        for (var id in gradebookAssignments) {
          var gba = gradebookAssignments[id]
          // Only accept assignments suitable to post, e.g. published, post_to_sis
          if (assignmentUtils.suitableToPost(gba)) {
            // Push a copy, and only of relevant attributes
            assignments.push(assignmentUtils.copyFromGradebook(gba))
          }
        }
        // A second loop is needed to ensure non-unique name errors are included
        // in hasError
        _.each(assignments, (a) => {
          a.original_error = assignmentUtils.hasError(assignments, a)
        })
        this.setState({ assignments: assignments })
      },

      setSections (sections) {
        this.setState({ sections: sections })
        this.setSelectedSection( this.getState().sectionToShow )
      },

      setSelectedSection (section) {
        var state = this.getState()
        var section_id = parseInt(section)
        var selected;
        if (section) {
          selected = {
            type: "section",
            id: section_id,
            sis_id: this.getSISSectionId(section_id)
          };
        } else {
          selected = {
            type: "course",
            id: state.course.id,
            sis_id: state.course.sis_id
          };
        }

        this.setState({ selected: selected, sectionToShow: section })
      },

      updateAssignment (assignment_id, newAttrs) {
        var assignments = this.getState().assignments
        var assignment = _.find(assignments, (a) => a.id == assignment_id)
        $.extend(assignment, newAttrs)
        this.setState({assignments: assignments})
      },

      saveAssignments () {
        var assignments = assignmentUtils.withOriginalErrorsNotIgnored(this.getState().assignments)
        var course_id = this.getState().course.id
        _.each(assignments, (a) => {
          assignmentUtils.saveAssignmentToCanvas(course_id, a)
        });
      },

      postGrades() {
        var assignments = assignmentUtils.notIgnored(this.getState().assignments)
        var selected = this.getState().selected
        assignmentUtils.postGradesThroughCanvas(selected, assignments)
      },

      getPage () {
        var state = this.getState()
        if (state.pleaseShowNeedsGradingPage) {
          return "needsGrading"
        } else {
          var originals = assignmentUtils.withOriginalErrors(this.getState().assignments)
          var withErrorsCount = _.keys(assignmentUtils.withErrors(state.assignments)).length
          if (withErrorsCount == 0 && (state.pleaseShowSummaryPage || originals.length == 0)) {
            return "summary"
          } else {
            return "corrections"
          }
        }
      }
    })

    return store
  };

  return PostGradesStore;
});