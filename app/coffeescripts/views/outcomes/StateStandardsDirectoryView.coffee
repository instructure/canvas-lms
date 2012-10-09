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
  'jquery'
  'underscore'
  'compiled/views/outcomes/OutcomesDirectoryView'
  'compiled/collections/OutcomeCollection'
], ($, _, OutcomesDirectoryView, OutcomeCollection) ->

  # for working with State Standards in the import dialog
  class StateStandardsDirectoryView extends OutcomesDirectoryView

    initialize: (opts) ->
      @outcomes = new OutcomeCollection # empty - not needed
      super
      @groups.on 'reset', @interceptMultiple
      @groups.on 'add', @interceptCommonCore
      @interceptMultiple @groups

    fetchOutcomes: ->
      # don't fetch outcomes

    # Calls @interceptCommonCore for multiple groups.
    interceptMultiple: (groups) =>
      _.each groups.models, @interceptCommonCore

    # Common core is a group in state standards.
    # We don't want to show it here because it's shown
    # one level up.
    interceptCommonCore: (group) =>
      if group.id is ENV.COMMON_CORE_GROUP_ID
        @groups.remove group, silent: true
        @reset()
