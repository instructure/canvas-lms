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
import PublishIconView from '..'
import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.simulate'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('PublishIconView', () => {
  let Publishable, publish, published, disabled, scheduled_publish

  beforeEach(() => {
    class PublishableClass extends Backbone.Model {
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

    Publishable = PublishableClass

    publish = new Publishable({published: false, unpublishable: true})
    published = new Publishable({published: true, unpublishable: true})
    disabled = new Publishable({published: true, unpublishable: false})
    scheduled_publish = new Publishable({
      published: false,
      unpublishable: true,
      publish_at: '2022-02-22T22:22:22Z',
    })
  })

  test('initialize publish', () => {
    const btnView = new PublishIconView({model: publish}).render()
    expect(btnView.isPublish()).toBeTruthy()
    expect(btnView.$text.html()).toMatch(/Publish/)
    expect(btnView.$text.html()).not.toMatch(/Published/)
  })

  test('initialize publish adds tooltip', () => {
    const btnView = new PublishIconView({model: publish}).render()
    expect(btnView.$el.data('tooltip')).toBe('left')
    expect(btnView.$el.attr('title')).toBe('Publish')
  })

  test('initialize published', () => {
    const btnView = new PublishIconView({model: published}).render()
    expect(btnView.isPublished()).toBeTruthy()
    expect(btnView.$text.html()).toMatch(/Published/)
  })

  test('initialize published adds tooltip', () => {
    const btnView = new PublishIconView({model: published}).render()
    expect(btnView.$el.data('tooltip')).toBe('left')
    expect(btnView.$el.attr('title')).toBe('Published')
  })

  test('initialize disabled published', () => {
    const btnView = new PublishIconView({model: disabled}).render()
    expect(btnView.isPublished()).toBeTruthy()
    expect(btnView.isDisabled()).toBeTruthy()
    expect(btnView.$text.html()).toMatch(/Published/)
  })

  test('initialize disabled adds tooltip', () => {
    const btnView = new PublishIconView({model: disabled}).render()
    expect(btnView.$el.data('tooltip')).toBe('left')
    expect(btnView.$el.attr('title')).toBe("can't unpublish")
  })

  test('initialize delayed adds tooltip', () => {
    fakeENV.setup({FEATURES: {scheduled_page_publication: true}})
    const btnView = new PublishIconView({model: scheduled_publish}).render()
    expect(btnView.isDelayedPublish()).toBeTruthy()
    expect(btnView.$el.data('tooltip')).toBe('left')
    expect(btnView.$el.attr('title')).toBe('Will publish on Feb 22')
    fakeENV.teardown()
  })

  test('ignores publish_at if FF is off', () => {
    const btnView = new PublishIconView({model: scheduled_publish}).render()
    expect(btnView.isDelayedPublish()).toBeFalsy()
    expect(btnView.$el.data('tooltip')).toBe('left')
    expect(btnView.$el.attr('title')).toBe('Publish')
  })
})
