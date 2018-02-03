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
  'jquery'
  'underscore'
  'Backbone'
  './ProgressBarView'
  './OutcomePopoverView'
  './OutcomeDialogView'
  'jst/grade_summary/outcome'
], ($, _, Backbone, ProgressBarView, OutcomePopoverView, OutcomeDialogView, template) ->

  class OutcomeView extends Backbone.View
    className: 'outcome'
    events:
      'click .more-details' : 'show'
      'keydown .more-details' : 'show'
    tagName: 'li'
    template: template

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    afterRender: ->
      @popover = new OutcomePopoverView({
        el: @$('.more-details')
        model: @model
      })
      @dialog = new OutcomeDialogView({
        model: @model
      })

    show: (e) ->
      @dialog.show e

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress

