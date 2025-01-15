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

import $ from 'jquery'
import Backbone from '@canvas/backbone'
import PaginatedCollection from '../../collections/PaginatedCollection'
import PaginatedCollectionView from '../PaginatedCollectionView'

class TestCollection extends PaginatedCollection {
  url = '/api/test'
}

class TestItemView extends Backbone.View {
  static defaultView = 'TestItem'

  initialize() {
    super.initialize(...arguments)
    this.render()
  }

  render() {
    this.$el.attr('role', 'listitem')
    this.$el.html(this.model.get('id'))
    return this
  }
}

describe('PaginatedCollectionView', () => {
  let collection
  let view
  let container

  beforeAll(() => {
    jest.useFakeTimers()
  })

  afterAll(() => {
    jest.useRealTimers()
  })

  beforeEach(() => {
    container = document.createElement('div')
    container.setAttribute('role', 'list')
    container.style.cssText = 'height: 500px; overflow: auto;'
    document.body.appendChild(container)

    collection = new TestCollection()
    view = new PaginatedCollectionView({
      collection,
      itemView: TestItemView,
      scrollContainer: container,
      itemViewOptions: {
        itemType: 'item',
      },
    })

    container.appendChild(view.el)
    view.render()
  })

  afterEach(() => {
    view.remove()
    container.remove()
  })

  it('shows loading indicator when fetching', () => {
    collection.trigger('beforeFetch')

    const loadingIndicator = view.el.querySelector('.paginatedLoadingIndicator')
    expect(loadingIndicator).toBeInTheDocument()
  })

  it('hides loading indicator after fetch completes', () => {
    collection.trigger('beforeFetch')
    collection.trigger('fetch')

    const loadingIndicator = view.el.querySelector('.paginatedLoadingIndicator')
    expect(loadingIndicator).not.toBeVisible()
  })

  it('detaches scroll listener when collection reaches last page', () => {
    const scrollSpy = jest.spyOn(view, 'checkScroll')
    collection.trigger('fetched:last')

    container.dispatchEvent(new Event('scroll'))
    expect(scrollSpy).not.toHaveBeenCalled()
  })

  it('fetches next page when scrolled near bottom', () => {
    const fetchSpy = jest.spyOn(collection, 'fetch')
    collection.canFetch = jest.fn().mockReturnValue(true)

    // Mock element dimensions for scroll calculation
    jest.spyOn($.fn, 'height').mockReturnValue(500)
    jest.spyOn($.fn, 'position').mockReturnValue({top: 0})
    jest.spyOn($.fn, 'scrollTop').mockReturnValue(400)

    view.checkScroll()

    expect(fetchSpy).toHaveBeenCalledWith({page: 'next'})
  })

  it('auto-fetches next page when autoFetch is enabled', () => {
    view.remove()
    view = new PaginatedCollectionView({
      collection,
      itemView: TestItemView,
      scrollContainer: container,
      autoFetch: true,
    })
    container.appendChild(view.el)
    view.render()

    const checkScrollSpy = jest.spyOn(view, 'checkScroll')
    collection.trigger('fetch')

    jest.runOnlyPendingTimers()
    expect(checkScrollSpy).toHaveBeenCalled()
  })

  it('continues fetching until last page when fetchItAll is enabled', () => {
    view.remove()
    view = new PaginatedCollectionView({
      collection,
      itemView: TestItemView,
      scrollContainer: container,
      fetchItAll: true,
    })
    container.appendChild(view.el)
    view.render()

    const checkScrollSpy = jest.spyOn(view, 'checkScroll')
    collection.trigger('fetch')

    jest.runOnlyPendingTimers()
    expect(checkScrollSpy).toHaveBeenCalled()
  })

  it('cleans up scroll listeners when removed', () => {
    const scrollSpy = jest.spyOn(view, 'checkScroll')
    view.remove()

    container.dispatchEvent(new Event('scroll'))
    expect(scrollSpy).not.toHaveBeenCalled()
  })
})
