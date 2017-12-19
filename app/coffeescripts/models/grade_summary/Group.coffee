#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'underscore'
  'Backbone'
  '../../util/natcompare'
], (_, {Model, Collection}, natcompare) ->
  class Group extends Model
    initialize: ->
      @set('outcomes', new Collection([], comparator: natcompare.byGet('friendly_name')))

    count: -> @get('outcomes').length


    statusCount: (status) ->
      @get('outcomes').filter((x) ->
        x.status() == status
      ).length

    mastery_count: ->
      @statusCount('mastery') + @statusCount('exceeds')

    remedialCount: ->
      @statusCount('remedial')

    undefinedCount: ->
      @statusCount('undefined')

    status: ->
      if @remedialCount() > 0
        "remedial"
      else
        if @mastery_count() == @count()
          "mastery"
        else if @undefinedCount() == @count()
          "undefined"
        else
          "near"

    started: ->
      true

    toJSON: ->
      _.extend super,
        count: @count()
        mastery_count: @mastery_count()
        started: @started()
        status: @status()
