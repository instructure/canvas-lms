// @ts-nocheck
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

import {find, keys, each} from 'lodash'
import $ from 'jquery'
import createStore from '@canvas/backbone/createStore'
import assignmentUtils from './assignmentUtils'
import type {AssignmentWithOverride} from '../default_gradebook/gradebook.d'

type State = {
  course: {
    id: string
    sis_id: string | null
  }
  selected: {
    id: string
    type: string
    sis_id?: string
  }
  sections: {}
  sectionToShow: string | null
  pleaseShowSummaryPage: boolean
  pleaseShowNeedsGradingPage: boolean
  assignments: Array<PartialAssignment>
}

type PartialAssignment = Pick<
  AssignmentWithOverride,
  | 'id'
  | 'name'
  | 'due_at'
  | 'needs_grading_count'
  | 'overrides'
  | 'please_ignore'
  | 'original_error'
>

function assignmentOverrideOriginalErrorCheck(a: {hadOriginalErrors: boolean}) {
  return (a.hadOriginalErrors = a.hadOriginalErrors === true)
}

const PostGradesStore = (initialState: {
  course: {
    id: string
    sis_id: string | null
  }
  selected?: {
    id: string
    type: string
  }
}) => {
  const store = $.extend(createStore<State>(initialState), {
    reset() {
      const assignments = this.getAssignments()
      each(assignments, a => (a.please_ignore = false))
      store.setState({
        assignments,
        pleaseShowNeedsGradingPage: false,
      })
    },

    hasAssignments() {
      const assignments = this.getAssignments()
      const assignmentsLength = typeof assignments !== 'undefined' ? assignments.length : 0
      return assignmentsLength > 0
    },

    getSISSectionId(section_id) {
      const sections = store.getState().sections
      return sections && sections[section_id] ? sections[section_id].sis_section_id : null
    },

    allOverrideIds(a: {
      overrides: {
        course_section_id: string
      }
    }) {
      const overrides: string[] = []
      each(a.overrides, o => {
        overrides.push(o.course_section_id)
      })
      return overrides
    },

    overrideForEveryone(a) {
      const overrides = this.allOverrideIds(a)
      const sections: string[] = keys(store.getState().sections)
      // @ts-expect-error
      const section_ids_with_no_overrides = $(sections).not(overrides).get()

      const section_for_everyone = find(section_ids_with_no_overrides, o => {
        return initialState?.selected?.id === o
      })
      return section_for_everyone
    },

    selectedSISId(): string | undefined {
      return store.getState().selected?.sis_id
    },

    setGradeBookAssignments(gradebookAssignments): void {
      const assignments: PartialAssignment[] = []
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
      each(assignments, a => {
        a.original_error = assignmentUtils.hasError(assignments, a)
      })
      store.setState({assignments})
    },

    setSections(sections) {
      store.setState({sections})
      const sectionToShow = store.getState().sectionToShow
      this.setSelectedSection(typeof sectionToShow === 'undefined' ? null : sectionToShow)
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
        typeof a.overrideForThisSection !== 'undefined' &&
        a.currentlySelected.type === 'course' &&
        a.currentlySelected.id.toString() === a.overrideForThisSection?.course_section_id
      ) {
        return a.due_at != null
      } else if (
        typeof a.overrideForThisSection !== 'undefined' &&
        a.currentlySelected.type === 'section' &&
        a.currentlySelected.id.toString() === a.overrideForThisSection?.course_section_id
      ) {
        return a.overrideForThisSection.due_at != null
      } else {
        return true
      }
    },

    getAssignments() {
      const assignments = store.getState().assignments
      const state = store.getState()
      if (state.selected?.type === 'section') {
        each(assignments, a => {
          a.recentlyUpdated = false
          a.currentlySelected = state.selected
          a.sectionCount = keys(state.sections).length
          a.overrideForThisSection = find(a.overrides, override => {
            return override.course_section_id === state.selected?.id
          })

          // Handle assignment with overrides and the 'Everyone Else' scenario with a section that does not have any overrides
          // cleanup overrideForThisSection logic
          if (typeof a.overrideForThisSection === 'undefined') {
            a.selectedSectionForEveryone = this.overrideForEveryone(a)
          }
        })
      } else {
        each(assignments, a => {
          a.recentlyUpdated = false
          a.currentlySelected = state.selected
          a.sectionCount = keys(state.sections).length

          // Course is currentlySlected with sections that have overrides AND are invalid
          a.overrideForThisSection = find(a.overrides, override => {
            return override.due_at == null || typeof override.due_at === 'object'
          })

          // Handle assignment with overrides and the 'Everyone Else' scenario with the course currentlySelected
          if (typeof a.overrideForThisSection === 'undefined') {
            a.selectedSectionForEveryone = this.overrideForEveryone(a)
          }
        })
      }
      return assignments
    },

    getAssignment(assignment_id: string) {
      const assignments = this.getAssignments()
      return find(assignments, a => a.id === assignment_id)
    },

    setSelectedSection(section: string | null) {
      const state = store.getState()
      const section_id = section === null ? 0 : parseInt(section, 10)
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
          id: state.course?.id,
          sis_id: state.course?.sis_id,
        }
      }

      store.setState({selected, sectionToShow: section})
    },

    updateAssignment(assignment_id: string, newAttrs: unknown) {
      const assignments = this.getAssignments()
      const assignment = find(assignments, a => a.id === assignment_id)
      $.extend(assignment, newAttrs)
      store.setState({assignments})
    },

    updateAssignmentDate(assignment_id: string, date) {
      const assignments = store.getState().assignments
      const assignment = find(assignments, a => a.id === assignment_id)
      // the assignment has an override and the override being updated is for the section that is currentlySelected update it
      if (
        assignment.currentlySelected.id.toString() ===
        assignment.overrideForThisSection?.course_section_id
      ) {
        assignment.overrideForThisSection.due_at = date
        assignment.please_ignore = false
        assignment.hadOriginalErrors = true

        store.setState({assignments})
      }

      // the section override being set from the course level of the sction dropdown
      else if (
        typeof assignment.overrideForThisSection !== 'undefined' &&
        assignment.currentlySelected.id.toString() !==
          assignment.overrideForThisSection?.course_section_id
      ) {
        assignment.overrideForThisSection.due_at = date
        assignment.please_ignore = false
        assignment.hadOriginalErrors = true

        store.setState({assignments})
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

    saveAssignments() {
      // TODO: fix this as Array<AssignmentWithOverride> cast
      const assignments = assignmentUtils.withOriginalErrorsNotIgnored(
        this.getAssignments() as Array<AssignmentWithOverride>
      )
      const course_id = store.getState().course?.id
      each(assignments, a => {
        assignmentOverrideOriginalErrorCheck(a)
        if (typeof course_id !== 'undefined') {
          assignmentUtils.saveAssignmentToCanvas(course_id, a)
        }
      })
    },

    postGrades() {
      // TODO: fix this as Array<AssignmentWithOverride> cast
      const assignments = assignmentUtils.notIgnored(
        this.getAssignments() as Array<AssignmentWithOverride>
      )
      const selected = store.getState().selected
      if (typeof selected !== 'undefined') {
        assignmentUtils.postGradesThroughCanvas(selected, assignments)
      }
    },

    getPage() {
      const state = store.getState()
      if (state.pleaseShowNeedsGradingPage) {
        return 'needsGrading'
      } else {
        // TODO: fix this as Array<AssignmentWithOverride> cast
        const originals = assignmentUtils.withOriginalErrors(
          this.getAssignments() as Array<AssignmentWithOverride>
        )
        const withErrorsCount = keys(
          assignmentUtils.withErrors(this.getAssignments() as Array<AssignmentWithOverride>)
        ).length
        if (withErrorsCount === 0 && (state.pleaseShowSummaryPage || originals.length === 0)) {
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
