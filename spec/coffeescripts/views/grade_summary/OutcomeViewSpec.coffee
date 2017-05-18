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

define [
  'underscore'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomePopoverView'
  'compiled/views/grade_summary/OutcomeDialogView'
  'compiled/views/grade_summary/OutcomeView'
  'compiled/views/grade_summary/ProgressBarView'
], (_, Outcome, OutcomePopoverView, OutcomeDialogView, OutcomeView, ProgressBarView) ->

  QUnit.module 'OutcomeViewSpec',
    setup: ->
      @outcomeView = new OutcomeView({
        el: $('<li><a class="more-details"></a></li>')
        model: new Outcome()
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @outcomeView.$el.find('a.more-details')
      }))

  test 'assign instance of ProgressBarView on init', ->
    ok @outcomeView.progress instanceof ProgressBarView

  test 'have after render behavior', ->
    ok _.isUndefined(@outcomeView.popover, 'precondition')

    @outcomeView.render()

    ok @outcomeView.popover instanceof OutcomePopoverView
    ok @outcomeView.dialog instanceof OutcomeDialogView

  test 'click & keydown .more-details', ->
    @outcomeView.render()
    showSpy = @stub(@outcomeView.dialog, 'show')
    @outcomeView.$el.find('a.more-details').trigger(@e('click'))
    ok showSpy.called

    showSpy.reset()

    @outcomeView.$el.find('a.more-details').trigger(@e('keydown'))
    ok showSpy.called
