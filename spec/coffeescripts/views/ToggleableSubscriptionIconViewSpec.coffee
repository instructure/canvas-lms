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
  'compiled/models/DiscussionTopic'
  'compiled/views/ToggleableSubscriptionIconView'
], ($, _, DiscussionTopic, SubscriptionIconView) ->

  QUnit.module 'SubscriptionIconView',
    setup: ->
      @model = new DiscussionTopic()
      @view = new SubscriptionIconView(model: @model)
      @view.render()
      @e = (name, options={}) -> $.Event(name, _.extend(options, {
        currentTarget: @view.el
      }))

  test 'hover', ->
    spy = @spy(@view, 'render')

    @view.$el.trigger(@e('focus'))
    ok spy.called
    ok @view.hovering
    spy.reset()

    @view.$el.trigger(@e('blur'))
    ok spy.called
    ok !@view.hovering
    spy.reset()

    @view.$el.trigger(@e('mouseenter'))
    ok spy.called
    ok @view.hovering
    spy.reset()

    @view.$el.trigger(@e('mouseleave'))
    ok spy.called
    ok !@view.hovering
    spy.reset()

  test 'click', ->
    unsubSpy = @stub(@model, 'topicUnsubscribe')
    subSpy = @stub(@model, 'topicSubscribe')
    @model.set({
      subscribed: false
      subscription_hold: false
    })
    ok !@view.dispalyStateDuringHover, 'precondition'

    @view.$el.trigger(@e('click'))
    ok subSpy.called
    ok !unsubSpy.called
    ok @view.displayStateDuringHover

    unsubSpy.reset()
    subSpy.reset()
    @view.displayStateDuringHover = false

    @model.set('subscribed', true)
    @view.$el.trigger(@e('click'))
    ok !subSpy.called
    ok unsubSpy.called
    ok @view.displayStateDuringHover

    unsubSpy.reset()
    subSpy.reset()
    @view.displayStateDuringHover = false
    @model.set({
      subscribed: false
      subscription_hold: true
    })

    @view.$el.trigger(@e('click'))
    ok !subSpy.called
    ok !unsubSpy.called
    ok !@view.displayStateDuringHover
