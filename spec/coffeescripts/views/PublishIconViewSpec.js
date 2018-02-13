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
import PublishIconView from 'compiled/views/PublishIconView'
import $ from 'jquery'
import 'helpers/jquery.simulate'

QUnit.module('PublishIconView', {
  setup() {
    class Publishable extends Backbone.Model {
      defaults = {
        published: false,
        publishable: true
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
  }
})

test('initialize publish', function() {
  const btnView = new PublishIconView({model: this.publish}).render()
  ok(btnView.isPublish())
  equal(btnView.$text.html().match(/Publish/).length, 1)
  ok(!btnView.$text.html().match(/Published/))
})

test('initialize publish adds tooltip', function() {
  const btnView = new PublishIconView({model: this.publish}).render()
  equal(btnView.$el.attr('data-tooltip'), '')
})

test('initialize published', function() {
  const btnView = new PublishIconView({model: this.published}).render()
  ok(btnView.isPublished())
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('initialize published adds tooltip', function() {
  const btnView = new PublishIconView({model: this.published}).render()
  equal(btnView.$el.attr('data-tooltip'), '')
})

test('initialize disabled published', function() {
  const btnView = new PublishIconView({model: this.disabled}).render()
  ok(btnView.isPublished())
  ok(btnView.isDisabled())
  equal(btnView.$text.html().match(/Published/).length, 1)
})

test('initialize disabled adds tooltip', function() {
  const btnView = new PublishIconView({model: this.disabled}).render()
  equal(btnView.$el.attr('data-tooltip'), '')
})
