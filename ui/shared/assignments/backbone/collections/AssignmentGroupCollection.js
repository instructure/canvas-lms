//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import ModuleCollection from '@canvas/modules/backbone/collections/ModuleCollection'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import AssignmentGroup from '../models/AssignmentGroup'
import SubmissionCollection from './SubmissionCollection'
import {isStudent} from '../models/Assignment'

const PER_PAGE_LIMIT = 50

export default class AssignmentGroupCollection extends PaginatedCollection {
  expandPeerReviewSubAssignments() {
    if (!ENV.FLAGS.peer_review_allocation_and_grading || !isStudent()) {
      return
    }

    this.each(group => {
      const assignments = group.get('assignments')
      if (!assignments) {
        return
      }

      const assignmentsToAdd = []

      assignments.each(assignment => {
        const peerReviewSubAssignment = assignment.get('peer_review_sub_assignment')
        if (peerReviewSubAssignment) {
          const peerReviewAssignment = {
            ...peerReviewSubAssignment,
            parent_assignment_id: assignment.get('id'),
            parent_assignment_name: assignment.get('name'),
            parent_peer_review_count: assignment.get('peer_review_count') || 0,
            is_peer_review_assignment: true,
            assignment_group_id: assignment.get('assignment_group_id'),
            course_id: assignment.get('course_id'),
            published: peerReviewSubAssignment.published ?? assignment.get('published'),
            html_url: assignment.get('html_url') + '/peer_reviews',
          }

          assignmentsToAdd.push(peerReviewAssignment)
        }
      })

      if (assignmentsToAdd.length > 0) {
        assignments.add(assignmentsToAdd)
      }
    })
  }

  loadModuleNames() {
    const modules = new ModuleCollection([], {course_id: this.course.id})
    modules.loadAll = true
    modules.skip_items = true
    modules.fetch()
    modules.on('fetched:last', () => {
      const moduleNames = {}
      for (const m of modules.toJSON()) {
        moduleNames[m.id] = m.name
      }

      for (const assignment of this.assignments()) {
        const moduleIds = assignment.get('module_ids') || []
        const assignmentModuleNames = moduleIds.map(id => moduleNames[id])
        assignment.set('modules', assignmentModuleNames)
      }
    })
  }

  assignments() {
    return this.toArray().flatMap(ag => ag.get('assignments').toArray())
  }

  canReadGrades() {
    return ENV.PERMISSIONS.read_grades
  }

  getObservedUserId() {
    if (savedObservedId(ENV.current_user?.id)) return savedObservedId(ENV.current_user?.id)
    if (ENV.observed_student_ids?.length === 1) return ENV.observed_student_ids[0]
  }

  getGrades() {
    if (this.canReadGrades()) {
      const collection = new SubmissionCollection()
      const observedUser = this.getObservedUserId()

      let baseUrl
      if (observedUser) {
        baseUrl = `${this.courseSubmissionsURL}?student_ids[]=${observedUser}&per_page=${PER_PAGE_LIMIT}`
      } else {
        baseUrl = `${this.courseSubmissionsURL}?per_page=${PER_PAGE_LIMIT}`
      }
      collection.url = () =>
        ENV.FEATURES.discussion_checkpoints
          ? `${baseUrl}&include[]=sub_assignment_submissions`
          : `${baseUrl}`

      collection.loadAll = true
      collection.on('fetched:last', () => this.loadGradesFromSubmissions(collection.toArray()))
      return collection.fetch()
    } else {
      return this.trigger('change:submissions')
    }
  }

  loadGradesFromSubmissions(submissions) {
    const submissionsHash = {}
    for (const submission of submissions) {
      submissionsHash[submission.get('assignment_id')] = submission
    }

    for (const assignment of this.assignments()) {
      const submission = submissionsHash[assignment.get('id')]
      if (submission) {
        if (submission.get('grade') != null) {
          const grade = parseFloat(submission.get('grade'))
          // may be a letter grade like 'A-'
          if (!Number.isNaN(grade)) {
            submission.set('grade', grade)
          }
        } else {
          submission.set('notYetGraded', true)
        }
        assignment.set('submission', submission)
      } else {
        // manually trigger a change so the UI can update appropriately.
        assignment.set('submission', null)
        assignment.trigger('change:submission')
      }
    }

    return this.trigger('change:submissions')
  }
}

AssignmentGroupCollection.prototype.loadAll = true
AssignmentGroupCollection.prototype.model = AssignmentGroup

AssignmentGroupCollection.optionProperty('course')
AssignmentGroupCollection.optionProperty('courseSubmissionsURL')

// TODO: this will also return the assignments discussion_topic if it is of
// that type, which we don't need.
Object.defineProperty(AssignmentGroupCollection.prototype, 'defaults', {
  get() {
    const include = ['assignments']
    if (ENV.FEATURES?.peer_review_allocation_and_grading) {
      include.push('peer_review')
    }
    return {
      params: {
        include,
      },
    }
  },
})

AssignmentGroupCollection.prototype.comparator = 'position'
