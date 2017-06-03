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
  'jquery'
  'underscore'
  'compiled/util/Popover'
  'compiled/models/grade_summary/Outcome'
  'compiled/views/grade_summary/OutcomePopoverView'
  'jst/outcomes/outcomePopover'
], ($, _, Popover, Outcome, OutcomePopoverView, template) ->

  QUnit.module 'OutcomePopoverViewSpec',
    setup: ->
      $(document.body).append('<div id="application"></div>')
      @popoverView = new OutcomePopoverView({
        el: $('<div><i></i></div>')
        model: new Outcome()
        template: template
      })
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @popoverView.el
      }))
      @clock = sinon.useFakeTimers()
    teardown: ->
      @clock.restore()

  test 'closePopover', ->
    ok _.isUndefined(@popoverView.popover, 'precondition')
    ok @popoverView.closePopover()

    @popoverView.popover = new Popover(@e('mouseleave'), @popoverView.render(), {
      verticalSide: 'bottom'
      manualOffset: 14
    })
    ok @popoverView.popover instanceof Popover

    ok @popoverView.closePopover()
    ok _.isUndefined(@popoverView.popover)

  test 'mouseenter', ->
    spy = @spy(@popoverView, 'openPopover')
    ok !@popoverView.inside, 'precondition'

    @popoverView.el.find('i').trigger(@e('mouseenter'))

    ok spy.called
    ok @popoverView.inside

  test 'mouseleave when no popover is present', ->
    spy = @spy(@popoverView, 'closePopover')

    ok _.isUndefined(@popoverView.popover), 'precondition'
    @popoverView.el.find('i').trigger(@e('mouseleave'))
    @clock.tick(@popoverView.TIMEOUT_LENGTH)
    ok !spy.called

  test 'mouseleave when popover is present', ->
    @popoverView.el.find('i').trigger('mouseenter')
    ok !_.isUndefined(@popoverView.popover), 'precondition'
    ok @popoverView.inside, 'precondition'

    spy = @spy(@popoverView, 'closePopover')
    @popoverView.el.find('i').trigger(@e('mouseleave'))
    @clock.tick(@popoverView.TIMEOUT_LENGTH)
    ok spy.called

  test 'openPopover', ->
    ok _.isUndefined(@popoverView.popover), 'precondition'
    elementSpy = @stub(@popoverView.outcomeLineGraphView, 'setElement')
    renderSpy = @stub(@popoverView.outcomeLineGraphView, 'render')

    @popoverView.openPopover(@e('mouseenter'))

    ok @popoverView.popover instanceof Popover
    ok elementSpy.called
    ok renderSpy.called
