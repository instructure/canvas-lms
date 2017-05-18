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
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/views/grade_summary/ProgressBarView'
  'jst/grade_summary/alignment'
], (I18n, _, Backbone, ProgressBarView, template) ->
  class AlignmentView extends Backbone.View
    tagName: 'li'
    className: 'alignment'
    template: template

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress
