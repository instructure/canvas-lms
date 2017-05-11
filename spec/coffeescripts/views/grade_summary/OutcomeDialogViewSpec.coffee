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
  'compiled/views/grade_summary/OutcomeDialogView'
  'compiled/views/grade_summary/OutcomeLineGraphView'
], (_, Outcome, OutcomeDialogView, OutcomeLineGraphView) ->

  QUnit.module 'OutcomeDialogViewSpec',
    setup: ->
      @outcomeDialogView = new OutcomeDialogView({
        model: new Outcome()
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @outcomeDialogView.el
      }))

  test 'assign instance of OutcomeLineGraphView on init', ->
    ok @outcomeDialogView.outcomeLineGraphView instanceof OutcomeLineGraphView

  test 'afterRender', ->
    setElementSpy = @stub(@outcomeDialogView.outcomeLineGraphView, 'setElement')
    renderSpy = @stub(@outcomeDialogView.outcomeLineGraphView, 'render')

    @outcomeDialogView.render()

    ok setElementSpy.called, 'should set linegraph element'
    ok renderSpy.called, 'should render line graph'

  test '#show', ->
    renderSpy = @stub(@outcomeDialogView, 'render')
    dialogSpy = @stub(@outcomeDialogView.$el, 'dialog')

    @outcomeDialogView.show(@e('mouseenter'))
    ok !renderSpy.called, 'should not render on any event'
    ok !dialogSpy.called, 'should not open dialog on any event'

    # enter; space
    _.each([13, 32], (i) =>
      @outcomeDialogView.show(@e('mouseenter', keyCode: i))
      ok renderSpy.called, "should render with keyCode #{i}"
      ok dialogSpy.called, "should open dialog with keyCode #{i}"
      renderSpy.reset()
      dialogSpy.reset()
    )

    # backspace; escape
    _.each([8, 27], (i) =>
      @outcomeDialogView.show(@e('mouseenter', keyCode: i))
      ok !renderSpy.called, "should not render with keyCode #{i}"
      ok !dialogSpy.called, "should not open dialog with keyCode #{i}"
    )

    @outcomeDialogView.show(@e('click'))
    ok renderSpy.called, "should render with click"
    ok dialogSpy.called, "should open dialog with click"
    renderSpy.reset()
    dialogSpy.reset()

  test 'toJSON', ->
    ok @outcomeDialogView.toJSON()['dialog'], 'should include dialog key'
