define([
  'jquery',
  'underscore',
  'i18n!modules',
  'jsx/shared/helpers/createStore',
  'jsx/gradezilla/SISGradePassback/assignmentUtils',
], ($, _, I18n, createStore, assignmentUtils) => {

  var PostGradesStore = (state) => {
    var store = $.extend(createStore(state), {

      reset () {
        var assignments = this.getAssignments()
        _.each(assignments, (a) => a.please_ignore = false)
        this.setState({
          assignments: assignments,
          pleaseShowNeedsGradingPage: false
        })
      },

      hasAssignments () {
        var assignments = this.getAssignments()
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

      allOverrideIds(a) {
        var overrides = []
        _.each(a.overrides, (o) => {
          overrides.push(o.course_section_id)
        })
        return overrides
      },

      overrideForEveryone(a) {
        var overrides = this.allOverrideIds(a)
        var sections = _.keys(this.getState().sections)
        var section_ids_with_no_overrides = $(sections).not(overrides).get();

        var section_for_everyone = _.find(section_ids_with_no_overrides, (o) => {
          return state.selected.id == o
        });
        return section_for_everyone
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

      validCheck(a) {
        if(a.overrideForThisSection != undefined && a.currentlySelected.type == 'course' && a.currentlySelected.id.toString() == a.overrideForThisSection.course_section_id){
          return a.due_at != null ? true : false
        }
        else if(a.overrideForThisSection != undefined && a.currentlySelected.type == 'section' && a.currentlySelected.id.toString() == a.overrideForThisSection.course_section_id){
          return a.overrideForThisSection.due_at != null ? true : false
        }
        else{
          return true
        }
      },

      getAssignments() {
        var assignments = this.getState().assignments
        var state = this.getState()
        if (state.selected.type == "section") {
          _.each(assignments, (a) => {
            a.recentlyUpdated = false
            a.currentlySelected = state.selected
            a.sectionCount = _.keys(state.sections).length
            a.overrideForThisSection = _.find(a.overrides, (override) => {
              return override.course_section_id == state.selected.id;
            });

            //Handle assignment with overrides and the 'Everyone Else' scenario with a section that does not have any overrides
            //cleanup overrideForThisSection logic
            if(a.overrideForThisSection == undefined){ a.selectedSectionForEveryone = this.overrideForEveryone(a) }
          });
        } else {
          _.each(assignments, (a) => {
            a.recentlyUpdated = false
            a.currentlySelected = state.selected
            a.sectionCount = _.keys(state.sections).length

            //Course is currentlySlected with sections that have overrides AND are invalid
            a.overrideForThisSection = _.find(a.overrides, (override) => {
              return override.due_at == null || typeof(override.due_at) == 'object';
            });

            //Handle assignment with overrides and the 'Everyone Else' scenario with the course currentlySelected
            if(a.overrideForThisSection == undefined){ a.selectedSectionForEveryone = this.overrideForEveryone(a) }
          });
        }
        return assignments;
      },

      getAssignment(assignment_id) {
        var assignments = this.getAssignments()
        return _.find(assignments, (a) => a.id == assignment_id)
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
        var assignments = this.getAssignments()
        var assignment = _.find(assignments, (a) => a.id == assignment_id)
        $.extend(assignment, newAttrs)
        this.setState({assignments: assignments})
      },

      updateAssignmentDate(assignment_id, date){
        var assignments = this.getState().assignments
        var assignment = _.find(assignments, (a) => a.id == assignment_id)
        //the assignment has an override and the override being updated is for the section that is currentlySelected update it
        if(assignment.overrideForThisSection != undefined && assignment.currentlySelected.id.toString() == assignment.overrideForThisSection.course_section_id) {
          assignment.overrideForThisSection.due_at = date
          assignment.please_ignore = false
          assignment.hadOriginalErrors = true

          this.setState({assignments: assignments})
        }

        //the section override being set from the course level of the sction dropdown
        else if(assignment.overrideForThisSection != undefined && assignment.currentlySelected.id.toString() != assignment.overrideForThisSection.course_section_id){
          assignment.overrideForThisSection.due_at = date
          assignment.please_ignore = false
          assignment.hadOriginalErrors = true

          this.setState({assignments: assignments})
        }

        //update normal assignment and the 'Everyone Else' scenario if the course is currentlySelected
        else {
          this.updateAssignment(assignment_id, {due_at: date, please_ignore: false, hadOriginalErrors: true})
        }
      },

      assignmentOverrideOrigianlErrorCheck(a) {
        a.hadOriginalErrors = a.hadOriginalErrors == true
      },

      saveAssignments () {
        var assignments = assignmentUtils.withOriginalErrorsNotIgnored(this.getAssignments())
        var course_id = this.getState().course.id
        _.each(assignments, (a) => {
          this.assignmentOverrideOrigianlErrorCheck(a)
          assignmentUtils.saveAssignmentToCanvas(course_id, a)
        });
      },

      postGrades() {
        var assignments = assignmentUtils.notIgnored(this.getAssignments())
        var selected = this.getState().selected
        assignmentUtils.postGradesThroughCanvas(selected, assignments)
      },

      getPage () {
        var state = this.getState()
        if (state.pleaseShowNeedsGradingPage) {
          return "needsGrading"
        } else {
          var originals = assignmentUtils.withOriginalErrors(this.getAssignments())
          var withErrorsCount = _.keys(assignmentUtils.withErrors(this.getAssignments())).length
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
