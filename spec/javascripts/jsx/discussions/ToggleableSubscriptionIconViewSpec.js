/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

define(
  ['jquery', 'compiled/views/ToggleableSubscriptionIconView', 'compiled/models/DiscussionTopic'],
  ($, ToggleableSubscriptionIconView, DiscussionTopic) => {
    QUnit.module('ToggleableSubscriptionIconView', {
      setup() {
        this.model = new DiscussionTopic()
        this.view = new ToggleableSubscriptionIconView({model: this.model})
      },
      teardown() {
        this.view.remove()
      }
    })

    test('shows proper SR text when the model is subscribed', function() {
      this.model.set('subscribed', true)
      this.view.setScreenreaderText()
      const actual = this.view.$el.attr('aria-label')
      const expected = 'You are subscribed to this topic. Click to unsubscribe.'
      equal(actual, expected)
    })

    test('shows proper SR text when the model is not subscribed', function() {
      this.model.set('subscribed', false)
      this.view.setScreenreaderText()
      const actual = this.view.$el.attr('aria-label')
      const expected = 'You are not subscribed to this topic. Click to subscribe.'
      equal(actual, expected)
    })
  }
)
