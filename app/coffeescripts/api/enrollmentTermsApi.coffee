#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'jsx/shared/CheatDepaginator'
], (_, Depaginate) ->
  listUrl = () =>
    ENV.ENROLLMENT_TERMS_URL

  deserializeTerms = (termGroups) ->
    _.flatten _.map termGroups, (group) ->
      _.map group.enrollment_terms, (term) ->

        groupID = term.grading_period_group_id
        newGroupID = if _.isNumber(groupID) then groupID.toString() else groupID
        {
          id: term.id.toString()
          name: term.name
          startAt: if term.start_at then new Date(term.start_at) else null
          endAt: if term.end_at then new Date(term.end_at) else null
          createdAt: if term.created_at then new Date(term.created_at) else null
          gradingPeriodGroupId: newGroupID
        }

  list: (terms) ->
    promise = new Promise (resolve, reject) =>
      Depaginate(listUrl())
           .then (response) ->
             resolve(deserializeTerms(response))
           .fail (error) ->
             reject(error)
    promise
