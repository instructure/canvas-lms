/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import PublishButtonView from '../index'
import $ from 'jquery'
import '@canvas/jquery/jquery.simulate'

class Publishable extends Backbone.Model {
  defaults() {
    return {
      published: false,
      publishable: true,
      publish_at: null,
      disabledForModeration: false,
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

describe('PublishButtonView', () => {
  let publish
  let published
  let disabled

  beforeEach(() => {
    publish = new Publishable({published: false, unpublishable: true})
    published = new Publishable({published: true, unpublishable: true})
    disabled = new Publishable({published: true, unpublishable: false})
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('initializes in publish state', () => {
    const btnView = new PublishButtonView({model: publish}).render()
    expect(btnView.isPublish()).toBe(true)
    expect(btnView.$text.html()).toMatch(/Publish/)
    expect(btnView.$text.html()).not.toMatch(/Published/)
  })

  it('initializes in published state', () => {
    const btnView = new PublishButtonView({model: published}).render()
    expect(btnView.isPublished()).toBe(true)
    expect(btnView.$text.html()).toMatch(/Published/)
  })

  it('initializes in disabled published state', () => {
    const btnView = new PublishButtonView({model: disabled}).render()
    expect(btnView.isPublished()).toBe(true)
    expect(btnView.isDisabled()).toBe(true)
    expect(btnView.$text.html()).toMatch(/Published/)
    expect(btnView.$el.attr('aria-label')).toMatch(/can't unpublish/)
  })

  it('renders provided publish text', () => {
    const testText = 'Test Publish Text'
    const btnView = new PublishButtonView({
      model: publish,
      publishText: testText,
    }).render()
    expect(btnView.$('.screenreader-only.accessible_label').text()).toBe(testText)
  })

  it('renders provided unpublish text', () => {
    const testText = 'Test Unpublish Text'
    const btnView = new PublishButtonView({
      model: published,
      unpublishText: testText,
    }).render()
    expect(btnView.$('.screenreader-only.accessible_label').text()).toBe(testText)
  })

  it('renders title in publish text', () => {
    const btnView = new PublishButtonView({
      model: publish,
      title: 'My Published Thing',
    }).render()
    expect(btnView.$('.screenreader-only.accessible_label').text()).toMatch(/My Published Thing/)
  })

  it('renders title in unpublish text', () => {
    const btnView = new PublishButtonView({
      model: published,
      title: 'My Unpublished Thing',
    }).render()
    expect(btnView.$('.screenreader-only.accessible_label').text()).toMatch(/My Unpublished Thing/)
  })

  describe('state management', () => {
    it('disables button', () => {
      const btnView = new PublishButtonView({model: publish}).render()
      expect(btnView.isDisabled()).toBe(false)
      btnView.disable()
      expect(btnView.isDisabled()).toBe(true)
    })

    it('enables button', () => {
      const btnView = new PublishButtonView({model: publish}).render()
      btnView.disable()
      expect(btnView.isDisabled()).toBe(true)
      btnView.enable()
      expect(btnView.isDisabled()).toBe(false)
    })

    it('resets states', () => {
      const btnView = new PublishButtonView({model: publish}).render()
      btnView.reset()
      expect(btnView.isPublish()).toBe(false)
      expect(btnView.isPublished()).toBe(false)
      expect(btnView.isUnpublish()).toBe(false)
    })
  })

  describe('mouse interactions', () => {
    it('maintains publish view on mouseenter', () => {
      const btnView = new PublishButtonView({model: publish}).render()
      btnView.$el.trigger('mouseenter')
      expect(btnView.$text.html()).toMatch(/Publish/)
    })

    it('changes to unpublish view on mouseenter when published', () => {
      const btnView = new PublishButtonView({model: published}).render()
      btnView.$el.trigger('mouseenter')
      expect(btnView.$text.html()).toMatch(/Unpublish/)
    })

    it('maintains published view on mouseenter when disabled', () => {
      const btnView = new PublishButtonView({model: disabled}).render()
      btnView.$el.trigger('mouseenter')
      expect(btnView.$text.html()).toMatch(/Published/)
    })

    it('restores published view on mouseleave', () => {
      const btnView = new PublishButtonView({model: published}).render()
      btnView.$el.trigger('mouseenter')
      btnView.$el.trigger('mouseleave')
      expect(btnView.$text.html()).toMatch(/Published/)
    })
  })

  describe('click interactions', () => {
    it('publishes on click when unpublished', async () => {
      const btnView = new PublishButtonView({model: publish}).render()
      btnView.$el.trigger('click')
      expect(btnView.model.get('published')).toBe(true)
    })

    it('unpublishes on click when published', async () => {
      const btnView = new PublishButtonView({model: published}).render()
      btnView.$el.trigger('mouseenter')
      btnView.$el.trigger('click')
      expect(btnView.model.get('published')).toBe(false)
    })

    it('does not unpublish on click when disabled', async () => {
      const btnView = new PublishButtonView({model: disabled}).render()
      btnView.$el.trigger('click')
      expect(btnView.model.get('published')).toBe(true)
    })
  })
})
