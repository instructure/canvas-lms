/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
    dfrd.reject({status: 0})
    return dfrd
  }

  unpublish() {
    this.set('published', false)
    const dfrd = $.Deferred()
    dfrd.reject({status: 0})
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

  describe('click interactions', () => {

    it('publish button renders fail to publish', async () => {
      jest.spyOn($, 'flashError')
      const btnView = new PublishButtonView({model: publish}).render()
      btnView.$el.trigger('click')
      expect(btnView.$text.html()).not.toMatch(/Published/)
      expect($.flashError).toHaveBeenCalledWith('This assignment has failed to publish')
    })

    it('unpublish button renders fail to unpublish', async () => {
      jest.spyOn($, 'flashError')
      const btnView = new PublishButtonView({model: published}).render()
      btnView.$el.trigger('click')
      expect(btnView.$text.html()).toMatch(/Published/)
      expect($.flashError).toHaveBeenCalledWith('This assignment has failed to unpublish')
    })

    it('publish button renders loading spinner only while publishing', async () => {
      jest.spyOn($, 'flashError')
      const renderSpinnerSpy = jest.spyOn(PublishButtonView.prototype, 'renderOverlayLoadingSpinner')
      const hideSpinnerSpy = jest.spyOn(PublishButtonView.prototype, 'hideOverlayLoadingSpinner')
      const btnView = new PublishButtonView({model: publish}).render()
      btnView.$el.trigger('click')

      expect(renderSpinnerSpy).toHaveBeenCalled()
      expect(hideSpinnerSpy).toHaveBeenCalled()
      expect(btnView.$text.html()).not.toMatch(/Published/)
      expect($.flashError).toHaveBeenCalledWith('This assignment has failed to publish')
    })

    it('unpublish button renders loading spinner only while unpublishing', async () => {
      jest.spyOn($, 'flashError')
      const renderSpinnerSpy = jest.spyOn(PublishButtonView.prototype, 'renderOverlayLoadingSpinner')
      const hideSpinnerSpy = jest.spyOn(PublishButtonView.prototype, 'hideOverlayLoadingSpinner')
      const btnView = new PublishButtonView({model: published}).render()
      btnView.$el.trigger('click')

      expect(renderSpinnerSpy).toHaveBeenCalled()
      expect(hideSpinnerSpy).toHaveBeenCalled()
      expect(btnView.$text.html()).toMatch(/Published/)
      expect($.flashError).toHaveBeenCalledWith('This assignment has failed to unpublish')
    })

  })
})
