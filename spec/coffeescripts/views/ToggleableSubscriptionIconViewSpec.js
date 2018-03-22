/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import DiscussionTopic from 'compiled/models/DiscussionTopic'
import SubscriptionIconView from 'compiled/views/ToggleableSubscriptionIconView'

QUnit.module('SubscriptionIconView', {
  setup() {
    this.model = new DiscussionTopic()
    this.view = new SubscriptionIconView({model: this.model})
    this.view.render()
    this.e = function(name, options = {}) {
      return $.Event(name, Object.assign(options, {currentTarget: this.view.el}))
    }
  }
})

test('hover', function() {
  const spy = this.spy(this.view, 'render')
  this.view.$el.trigger(this.e('focus'))
  ok(spy.called)
  ok(this.view.hovering)
  spy.reset()
  this.view.$el.trigger(this.e('blur'))
  ok(spy.called)
  ok(!this.view.hovering)
  spy.reset()
  this.view.$el.trigger(this.e('mouseenter'))
  ok(spy.called)
  ok(this.view.hovering)
  spy.reset()
  this.view.$el.trigger(this.e('mouseleave'))
  ok(spy.called)
  ok(!this.view.hovering)
  return spy.reset()
})

test('click', function() {
  const unsubSpy = this.stub(this.model, 'topicUnsubscribe')
  const subSpy = this.stub(this.model, 'topicSubscribe')
  this.model.set({
    subscribed: false,
    subscription_hold: false
  })
  ok(!this.view.dispalyStateDuringHover, 'precondition')
  this.view.$el.trigger(this.e('click'))
  ok(subSpy.called)
  ok(!unsubSpy.called)
  ok(this.view.displayStateDuringHover)
  unsubSpy.reset()
  subSpy.reset()
  this.view.displayStateDuringHover = false
  this.model.set('subscribed', true)
  this.view.$el.trigger(this.e('click'))
  ok(!subSpy.called)
  ok(unsubSpy.called)
  ok(this.view.displayStateDuringHover)
  unsubSpy.reset()
  subSpy.reset()
  this.view.displayStateDuringHover = false
  this.model.set({
    subscribed: false,
    subscription_hold: true
  })
  this.view.$el.trigger(this.e('click'))
  ok(!subSpy.called)
  ok(!unsubSpy.called)
  ok(!this.view.displayStateDuringHover)
})
