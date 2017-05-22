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
  'Backbone'
  'underscore'
  'jquery'
], ({Model}, _, $) ->

  class QuickStartAssignment extends Model

    url: ->
      "/api/v1/courses/#{@get 'course_id'}/assignments"

    defaults:
      name: 'No Title'
      due_at: null
      points_possible: null
      grading_type: 'points'
      submission_types: 'online_upload,online_text_entry'
      course_id: null

    toJSON: ->
      assignment: super

