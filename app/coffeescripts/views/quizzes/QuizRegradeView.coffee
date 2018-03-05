#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'Backbone'
  '../DialogBaseView'
  'jst/quiz/regrade'
], ($, _, Backbone, DialogBaseView, template) ->

  class QuizRegradeView extends DialogBaseView

    template: template

    @optionProperty 'regradeDisabled'
    @optionProperty 'regradeOption'
    @optionProperty 'multipleAnswer'
    @optionProperty 'question'

    events:
      "click .regrade_option": "enableUpdate"

    initialize: ->
      super
      @render()

    render: ->
      @$el.parent().find('a').first().focus()
      unless @regradeOption
        @$el.parent().find('.btn-primary').attr('disabled', true)
      super

    defaultOptions: ->
      title: "Regrade Options"
      width: "600px"

    update: =>
      selectedOption = @$el.find(".regrade_option:checked")
      @close()
      @trigger('update', selectedOption)

    enableUpdate: ->
      @$el.parent().find('.btn-primary').attr('disabled', false)
