/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from 'Backbone'
import PublishButtonView from 'compiled/views/PublishButtonView'
import $ from 'jquery'
import 'helpers/jquery.simulate'

QUnit.module('PublishButtonView', {
  setup() {
    class Publishable extends Backbone.Model {
      defaults() {
        return {
          published: false,
          publishable: true,
          disabledForModeration: false
        }
      }

      publish() {
        this.set('published', true)
        const dfrd = $.Deferred()
        dfrd.resolve()
        return dfrd
      }
      unpublish() {
        this.set('published', false)
        const dfrd = $.Deferred()
        dfrd.resolve()
        return dfrd
      }
      disabledMessage() {
        return "can't unpublish"
      }
    }
    this.publishable = Publishable
    this.publish = new Publishable({published: false, unpublishable: true})
    this.published = new Publishable({published: true, unpublishable: true})
    this.disabled = new Publishable({published: true, unpublishable: false})
    this.moderationDisabled = new Publishable({disabledForModeration: true})
  }
})

test('initialize publish', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  ok(btnView.isPublish())
  equal(btnView.$text.html().match(/Publish/).length, 1)
  ok(!btnView.$text.html().match(/Published/))
})

test('initialize published', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  ok(btnView.isPublished())
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('initialize disabled published', function() {
  const btnView = new PublishButtonView({model: this.disabled}).render()
  ok(btnView.isPublished())
  ok(btnView.isDisabled())
  equal(btnView.$text.html().match(/Published/).length, 1)
  equal(btnView.$el.attr('aria-label').match(/can't unpublish/).length, 1)
})

test('should render the provided publish text when given', function() {
  const testText = 'Test Publish Text'
  const btnView = new PublishButtonView({
    model: this.publish,
    publishText: testText
  }).render()
  equal(btnView.$('.screenreader-only.accessible_label').text(), testText)
})

test('should render the provided unpublish text when given', function() {
  const testText = 'Test Unpublish Text'
  const btnView = new PublishButtonView({
    model: this.published,
    unpublishText: testText
  }).render()
  equal(btnView.$('.screenreader-only.accessible_label').text(), testText)
})

test('should render title in publish text when given', function() {
  const btnView = new PublishButtonView({
    model: this.publish,
    title: 'My Published Thing'
  }).render()
  equal(
    btnView
      .$('.screenreader-only.accessible_label')
      .text()
      .match(/My Published Thing/).length,
    1
  )
})

test('should render title in unpublish test when given', function() {
  const btnView = new PublishButtonView({
    model: this.published,
    title: 'My Unpublished Thing'
  }).render()
  equal(
    btnView
      .$('.screenreader-only.accessible_label')
      .text()
      .match(/My Unpublished Thing/).length,
    1
  )
})

test('disable should add disabled state', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  ok(!btnView.isDisabled())
  btnView.disable()
  ok(btnView.isDisabled())
})

test('enable should remove disabled state', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  btnView.disable()
  ok(btnView.isDisabled())
  btnView.enable()
  ok(!btnView.isDisabled())
})

test('reset should disable states', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  btnView.reset()
  ok(!btnView.isPublish())
  ok(!btnView.isPublished())
  ok(!btnView.isUnpublish())
})

test('mouseenter publish button should remain publish button', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  btnView.$el.trigger('mouseenter')
  ok(btnView.isPublish())
})

test('mouseenter publish button should not change text or icon', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  btnView.$el.trigger('mouseenter')
  equal(btnView.$text.html().match(/Publish/).length, 1)
  ok(!btnView.$text.html().match(/Published/))
})

test('mouseenter published button should remove published state', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  btnView.$el.trigger('mouseenter')
  ok(!btnView.isPublished())
})

test('mouseenter published button should add add unpublish state', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  btnView.$el.trigger('mouseenter')
  ok(btnView.isUnpublish())
})

test('mouseenter published button should change icon and text', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  btnView.$el.trigger('mouseenter')
  equal(btnView.$text.html().match(/Unpublish/).length, 1)
})

test('mouseenter disabled published button should keep published state', function() {
  const btnView = new PublishButtonView({model: this.disabled}).render()
  btnView.$el.trigger('mouseenter')
  ok(btnView.isPublished())
})

test('mouseenter disabled published button should not change text or icon', function() {
  const btnView = new PublishButtonView({model: this.disabled}).render()
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('mouseleave published button should add published state', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('mouseleave')
  ok(btnView.isPublished())
})

test('mouseleave published button should remove unpublish state', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('mouseleave')
  ok(!btnView.isUnpublish())
})

test('mouseleave published button should change icon and text', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('mouseleave')
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('click publish should trigger publish event', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  let triggered = false
  btnView.on('publish', () => (triggered = true))
  btnView.$el.trigger('click')
  ok(triggered)
})

test('publish event callback should transition to published', function() {
  const btnView = new PublishButtonView({model: this.publish}).render()
  ok(btnView.isPublish())
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('click')
  ok(!btnView.isPublish())
  ok(btnView.isPublished())
})

test('publish event callback should transition back to publish if rejected', function() {
  this.publishable.prototype.publish = function() {
    this.set('published', false)
    return $.Deferred().reject()
  }
  const btnView = new PublishButtonView({model: this.publish}).render()
  ok(btnView.isPublish())
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('click')
  ok(btnView.isPublish())
  ok(!btnView.isPublished())
})

test('click published should trigger unpublish event', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  let triggered = false
  btnView.on('unpublish', () => (triggered = true))
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('click')
  ok(triggered)
})

test('published event callback should transition to publish', function() {
  const btnView = new PublishButtonView({model: this.published}).render()
  ok(btnView.isPublished())
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('click')
  ok(!btnView.isUnpublish())
  ok(btnView.isPublish())
})

test('published event callback should transition back to published if rejected', function() {
  this.publishable.prototype.unpublish = function() {
    this.set('published', true)
    const response = {
      responseText: JSON.stringify({
        errors: {published: [{message: "Can't unpublish if there are already student submissions"}]}
      })
    }
    const dfrd = $.Deferred()
    dfrd.reject(response)
    return dfrd
  }
  const btnView = new PublishButtonView({model: this.published}).render()
  ok(btnView.isPublished())
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('click')
  ok(!btnView.isUnpublish())
  ok(btnView.isPublished())
})

test('click disabled published button should not trigger publish event', function() {
  const btnView = new PublishButtonView({model: this.disabled}).render()
  ok(btnView.isPublished())
  btnView.$el.trigger('mouseenter')
  btnView.$el.trigger('click')
  ok(!btnView.isPublish())
})

test('publish button is disabled if assignment is disabled for moderation', function() {
  const buttonView = new PublishButtonView({model: this.moderationDisabled}).render()
  strictEqual(buttonView.isDisabled(), true)
})
