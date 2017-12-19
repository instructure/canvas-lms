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
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/PostToSisSelector'
  '../../jquery/toggleAccessibly'
], (Backbone, _, $, template, toggleAccessibly) ->

  class PostToSisSelector extends Backbone.View

    template: template

    POST_TO_SIS              = '#assignment_post_to_sis'

    els: do ->
      els = {}
      els[POST_TO_SIS] = '$postToSis'
      els

    @optionProperty 'parentModel'
    @optionProperty 'nested'

    toJSON: =>
      postToSIS: @parentModel.postToSIS()
      postToSISName: @parentModel.postToSISName()
      nested: @nested
      prefix: 'assignment' if @nested
