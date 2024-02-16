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

import Backbone from '@canvas/backbone'
import PublishIconView from '@canvas/publish-icon-view'
import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.simulate'
import fakeENV from 'helpers/fakeENV'

QUnit.module('PublishIconView', {
  setup() {
    class Publishable extends Backbone.Model {
      defaults = {
        published: false,
        publishable: true,
      }

      publish() {
        this.set('published', true)
        return $.Deferred().resolve()
      }

      unpublish() {
        this.set('published', false)
        return $.Deferred().resolve()
      }

      disabledMessage() {
        return "can't unpublish"
      }
    }

    this.publishable = Publishable

    this.publish = new Publishable({published: false, unpublishable: true})
    this.published = new Publishable({published: true, unpublishable: true})
    this.disabled = new Publishable({published: true, unpublishable: false})
    this.scheduled_publish = new Publishable({
      published: false,
      unpublishable: true,
      publish_at: '2022-02-22T22:22:22Z',
    })
  },
})

test('initialize publish', function () {
  const btnView = new PublishIconView({model: this.publish}).render()
  ok(btnView.isPublish())
  equal(btnView.$text.html().match(/Publish/).length, 1)
  ok(!btnView.$text.html().match(/Published/))
})

test('initialize publish adds tooltip', function () {
  const btnView = new PublishIconView({model: this.publish}).render()
  equal(btnView.$el.data('tooltip'), 'left')
  equal(btnView.$el.attr('title'), 'Publish')
})

test('initialize published', function () {
  const btnView = new PublishIconView({model: this.published}).render()
  ok(btnView.isPublished())
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('initialize published adds tooltip', function () {
  const btnView = new PublishIconView({model: this.published}).render()
  equal(btnView.$el.data('tooltip'), 'left')
  equal(btnView.$el.attr('title'), 'Published')
})

test('initialize disabled published', function () {
  const btnView = new PublishIconView({model: this.disabled}).render()
  ok(btnView.isPublished())
  ok(btnView.isDisabled())
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('initialize disabled adds tooltip', function () {
  const btnView = new PublishIconView({model: this.disabled}).render()
  equal(btnView.$el.data('tooltip'), 'left')
  equal(btnView.$el.attr('title'), "can't unpublish")
})

test('initialize delayed adds tooltip', function () {
  fakeENV.setup({FEATURES: {scheduled_page_publication: true}})
  const btnView = new PublishIconView({model: this.scheduled_publish}).render()
  ok(btnView.isDelayedPublish())
  equal(btnView.$el.data('tooltip'), 'left')
  equal(btnView.$el.attr('title'), 'Will publish on Feb 22')
  fakeENV.teardown()
})

test('ignores publish_at if FF is off', function () {
  const btnView = new PublishIconView({model: this.scheduled_publish}).render()
  notOk(btnView.isDelayedPublish())
  equal(btnView.$el.data('tooltip'), 'left')
  equal(btnView.$el.attr('title'), 'Publish')
})
