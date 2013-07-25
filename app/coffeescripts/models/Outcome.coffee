#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'Backbone'
], (Backbone) ->

  class Outcome extends Backbone.Model

    name: ->
      @get 'title'

    # The api returns abbreviated data by default
    # which in most cases means there's no description.
    # Run fetch() to get all the data.
    isAbbreviated: ->
      !@has('description')

    # overriding to work with both outcome and outcome link responses
    parse: (resp) ->
      if resp.outcome # it's an outcome link
        @outcomeLink = resp
        @outcomeGroup = resp.outcome_group
        resp.outcome
      else
        resp

    setUrlTo: (action) ->
      @url =
        switch action
          when 'add'    then @outcomeGroup.outcomes_url
          when 'edit'   then @get 'url'
          when 'delete' then @outcomeLink.url
