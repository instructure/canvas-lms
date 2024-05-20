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

const PER_PAGE_LIMIT = 50

export default class AssignmentGroupCollection extends PaginatedCollection {
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
    return this.chain()
      .map(ag => ag.get('assignments').toArray())
      .flatten()
      .value()
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

      if (observedUser) {
        collection.url = () =>
          `${this.courseSubmissionsURL}?student_ids[]=${observedUser}&per_page=${PER_PAGE_LIMIT}`
      } else {
        collection.url = () => `${this.courseSubmissionsURL}?per_page=${PER_PAGE_LIMIT}`
      }
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
AssignmentGroupCollection.prototype.defaults = {
  params: {
    include: ['assignments'],
  },
}

AssignmentGroupCollection.prototype.comparator = 'position'
