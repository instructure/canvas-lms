/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import _ from 'underscore'
import createStore from '@canvas/util/createStore'
import assignmentUtils from './assignmentUtils'

type State = {
  course: {
    id: string
    sis_id: string
  }
  selected: {
    id: string
    type: string
  }
  sections: {}
}

const PostGradesStore = initialState => {
  const store = $.extend(createStore(initialState), {
    reset() {
      const assignments = this.getAssignments()
      _.each(assignments, a => (a.please_ignore = false))
      this.setState({
        assignments,
        pleaseShowNeedsGradingPage: false,
      })
    },

    hasAssignments() {
      const assignments = this.getAssignments()
      if (assignments?.length > 0) {
        return true
      } else {
        return false
      }
    },

    getSISSectionId(section_id) {
      const sections = this.getState().sections
      return sections && sections[section_id] ? sections[section_id].sis_section_id : null
    },

    allOverrideIds(a: {
      overrides: {
        course_section_id: string
      }
    }) {
      const overrides: string[] = []
      _.each(a.overrides, o => {
        overrides.push(o.course_section_id)
      })
      return overrides
    },

    overrideForEveryone(a) {
      const overrides = this.allOverrideIds(a)
      const sections = _.keys(this.getState().sections)
      const section_ids_with_no_overrides = $(sections).not(overrides).get()

      const section_for_everyone = _.find(section_ids_with_no_overrides, o => {
        return initialState.selected.id == o
      })
      return section_for_everyone
    },

    selectedSISId() {
      return this.getState().selected.sis_id
    },

    setGradeBookAssignments(gradebookAssignments) {
      const assignments = []
      for (const id in gradebookAssignments) {
        const gba = gradebookAssignments[id]
        // Only accept assignments suitable to post, e.g. published, post_to_sis
        if (assignmentUtils.suitableToPost(gba)) {
          // Push a copy, and only of relevant attributes
          assignments.push(assignmentUtils.copyFromGradebook(gba))
        }
      }
      // A second loop is needed to ensure non-unique name errors are included
      // in hasError
      _.each(assignments, a => {
        a.original_error = assignmentUtils.hasError(assignments, a)
      })
      this.setState({assignments})
    },

    setSections(sections) {
      this.setState({sections})
      this.setSelectedSection(this.getState().sectionToShow)
    },

    validCheck(a: {
      due_at: string | null
      currentlySelected: {
        id: string
        type: string
      }
      overrideForThisSection: {
        course_section_id: string
        due_at: string | null
      }
    }) {
      if (
        a.overrideForThisSection != undefined &&
        a.currentlySelected.type === 'course' &&
        a.currentlySelected.id.toString() === a.overrideForThisSection?.course_section_id
      ) {
        return a.due_at != null
      } else if (
        a.overrideForThisSection != undefined &&
        a.currentlySelected.type === 'section' &&
        a.currentlySelected.id.toString() === a.overrideForThisSection?.course_section_id
      ) {
        return a.overrideForThisSection.due_at != null
      } else {
        return true
      }
    },

    getAssignments() {
      const assignments = this.getState().assignments
      const state: {
        selected: {
          id: string
          type: string
        }
        sections: {}
      } = this.getState()
      if (state.selected.type === 'section') {
        _.each(assignments, a => {
          a.recentlyUpdated = false
          a.currentlySelected = state.selected
          a.sectionCount = _.keys(state.sections).length
          a.overrideForThisSection = _.find(a.overrides, override => {
            return override.course_section_id === state.selected.id
          })

          // Handle assignment with overrides and the 'Everyone Else' scenario with a section that does not have any overrides
          // cleanup overrideForThisSection logic
          if (a.overrideForThisSection == undefined) {
            a.selectedSectionForEveryone = this.overrideForEveryone(a)
          }
        })
      } else {
        _.each(assignments, a => {
          a.recentlyUpdated = false
          a.currentlySelected = state.selected
          a.sectionCount = _.keys(state.sections).length

          // Course is currentlySlected with sections that have overrides AND are invalid
          a.overrideForThisSection = _.find(a.overrides, override => {
            return override.due_at == null || typeof override.due_at === 'object'
          })

          // Handle assignment with overrides and the 'Everyone Else' scenario with the course currentlySelected
          if (a.overrideForThisSection == undefined) {
            a.selectedSectionForEveryone = this.overrideForEveryone(a)
          }
        })
      }
      return assignments
    },

    getAssignment(assignment_id: string) {
      const assignments = this.getAssignments()
      return _.find(assignments, a => a.id == assignment_id)
    },

    setSelectedSection(section) {
      const state: State = this.getState()
      const section_id = parseInt(section, 10)
      let selected
      if (section) {
        selected = {
          type: 'section',
          id: section_id,
          sis_id: this.getSISSectionId(section_id),
        }
      } else {
        selected = {
          type: 'course',
          id: state.course.id,
          sis_id: state.course.sis_id,
        }
      }

      this.setState({selected, sectionToShow: section})
    },

    updateAssignment(assignment_id: string, newAttrs) {
      const assignments = this.getAssignments()
      const assignment = _.find(assignments, a => a.id == assignment_id)
      $.extend(assignment, newAttrs)
      this.setState({assignments})
    },

    updateAssignmentDate(assignment_id: string, date) {
      const assignments = this.getState().assignments
      const assignment = _.find(assignments, a => a.id == assignment_id)
      // the assignment has an override and the override being updated is for the section that is currentlySelected update it
      if (
        assignment.currentlySelected.id.toString() ===
        assignment.overrideForThisSection?.course_section_id
      ) {
        assignment.overrideForThisSection.due_at = date
        assignment.please_ignore = false
        assignment.hadOriginalErrors = true

        this.setState({assignments})
      }

      // the section override being set from the course level of the sction dropdown
      else if (
        assignment.overrideForThisSection != undefined &&
        assignment.currentlySelected.id.toString() !==
          assignment.overrideForThisSection?.course_section_id
      ) {
        assignment.overrideForThisSection.due_at = date
        assignment.please_ignore = false
        assignment.hadOriginalErrors = true

        this.setState({assignments})
      }

      // update normal assignment and the 'Everyone Else' scenario if the course is currentlySelected
      else {
        this.updateAssignment(assignment_id, {
          due_at: date,
          please_ignore: false,
          hadOriginalErrors: true,
        })
      }
    },

    assignmentOverrideOrigianlErrorCheck(a) {
      a.hadOriginalErrors = a.hadOriginalErrors == true
    },

    saveAssignments() {
      const assignments = assignmentUtils.withOriginalErrorsNotIgnored(this.getAssignments())
      const course_id = this.getState().course.id
      _.each(assignments, a => {
        this.assignmentOverrideOrigianlErrorCheck(a)
        assignmentUtils.saveAssignmentToCanvas(course_id, a)
      })
    },

    postGrades() {
      const assignments = assignmentUtils.notIgnored(this.getAssignments())
      const selected = this.getState().selected
      assignmentUtils.postGradesThroughCanvas(selected, assignments)
    },

    getPage() {
      const state = this.getState()
      if (state.pleaseShowNeedsGradingPage) {
        return 'needsGrading'
      } else {
        const originals = assignmentUtils.withOriginalErrors(this.getAssignments())
        const withErrorsCount = _.keys(assignmentUtils.withErrors(this.getAssignments())).length
        if (withErrorsCount == 0 && (state.pleaseShowSummaryPage || originals.length === 0)) {
          return 'summary'
        } else {
          return 'corrections'
        }
      }
    },
  })

  return store
}

export default PostGradesStore
