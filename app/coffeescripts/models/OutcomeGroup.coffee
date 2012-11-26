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

  class OutcomeGroup extends Backbone.Model

    name: ->
      @get 'title'

    # The api returns abbreviated data by default
    # which in most cases means there's no description.
    # Run fetch() to get all the data.
    isAbbreviated: ->
      !@has('description')

    setUrlTo: (action) ->
      @url =
        switch action
          when 'add' then @get('parent_outcome_group').subgroups_url
          when 'edit', 'delete' then @get 'url'
