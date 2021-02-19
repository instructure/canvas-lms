#
# Copyright (C) 2013 - present Instructure, Inc.
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

import {Model} from 'Backbone'
import _ from 'underscore'

export default class CreateUserList extends Model

  defaults:
    roles: null
    sections: null
    course_section_id: null
    role_id: null
    user_list: null
    readURL: null
    updateURL: null
    step: 1
    enrolledUsers: null

  present: ->
    @attributes

  toJSON: ->
    attrs = [
      'course_section_id'
      'role_id'
      'user_list'
      'limit_privileges_to_course_section'
    ]
    json = _.pick @attributes, attrs...

  url: ->
    if @get('step') is 1
      @get 'readURL'
    else
      @get 'updateURL'

  incrementStep: ->
    @set 'step', @get('step') + 1

  startOver: ->
    @set 'users', null
    @set 'step', 1

  parse: (data) ->
    if _.isArray(data)
      enrolledUsers: data
    else
      data

