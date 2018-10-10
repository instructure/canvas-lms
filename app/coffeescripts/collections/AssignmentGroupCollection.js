#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'Backbone'
  '../collections/PaginatedCollection'
  '../models/AssignmentGroup'
  'underscore'
  '../collections/SubmissionCollection'
  '../collections/ModuleCollection'
], ($, Backbone, PaginatedCollection, AssignmentGroup, _, SubmissionCollection, ModuleCollection) ->

  PER_PAGE_LIMIT = 50

  class AssignmentGroupCollection extends PaginatedCollection

    loadAll: true
    model: AssignmentGroup

    @optionProperty 'course'
    @optionProperty 'courseSubmissionsURL'

    # TODO: this will also return the assignments discussion_topic if it is of
    # that type, which we don't need.
    defaults:
      params:
        include: ["assignments"]

    loadModuleNames: ->
      modules = new ModuleCollection([], {course_id: @course.id})
      modules.loadAll = true
      modules.skip_items = true
      modules.fetch()
      modules.on 'fetched:last', =>
        moduleNames = {}
        for m in modules.toJSON()
          moduleNames[m.id] = m.name

        for assignment in @assignments()
          assignmentModuleNames = _(assignment.get 'module_ids')
            .map (id) -> moduleNames[id]
          assignment.set('modules', assignmentModuleNames)

    assignments: ->
      @chain()
        .map((ag) -> ag.get('assignments').toArray())
        .flatten()
        .value()

    comparator: 'position'

    canReadGrades: ->
      ENV.PERMISSIONS.read_grades

    getGrades: ->
      if @canReadGrades() && ENV.observed_student_ids.length <= 1
        collection = new SubmissionCollection
        if ENV.observed_student_ids.length == 1
          collection.url = => "#{@courseSubmissionsURL}?student_ids[]=#{ENV.observed_student_ids[0]}&per_page=#{PER_PAGE_LIMIT}"
        else
          collection.url = => "#{@courseSubmissionsURL}?per_page=#{PER_PAGE_LIMIT}"
        collection.loadAll = true
        collection.on 'fetched:last', =>
          @loadGradesFromSubmissions(collection.toArray())
        collection.fetch()
      else
        @trigger 'change:submissions'

    loadGradesFromSubmissions: (submissions) ->
      submissionsHash = {}
      for submission in submissions
        submissionsHash[submission.get('assignment_id')] = submission

      for assignment in @assignments()
        submission = submissionsHash[assignment.get('id')]
        if submission
          if submission.get('grade')?
            grade = parseFloat submission.get('grade')
            # may be a letter grade like 'A-'
            if !isNaN grade
              submission.set 'grade', grade
          else
            submission.set 'notYetGraded', true
          assignment.set 'submission', submission
        else
          # manually trigger a change so the UI can update appropriately.
          assignment.set 'submission', null
          assignment.trigger 'change:submission'

      @trigger 'change:submissions'
