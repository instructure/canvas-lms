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

import WikiPageRevisionsCollection from '../../collections/WikiPageRevisionsCollection'
import WikiPageRevisionsView from '../WikiPageRevisionsView'

describe('WikiPageRevisionsView', () => {
  let view, collection, container

  beforeEach(() => {
    container = document.createElement('div')
    container.innerHTML = '<div id="main"><div id="content"></div></div>'
    document.body.appendChild(container)
    collection = new WikiPageRevisionsCollection()
    view = new WikiPageRevisionsView({collection})
    view.$el.appendTo('#content')
    view.render()
  })

  afterEach(() => {
    container.remove()
  })

  describe('model selection', () => {
    it('sets selected attribute when selecting a model', () => {
      // Arrange
      collection.add({revision_id: 21})
      collection.add({revision_id: 37})
      expect(collection.models).toHaveLength(2)

      // Act
      view.setSelectedModelAndView(collection.models[0], collection.models[0].view)

      // Assert
      expect(collection.models[0].get('selected')).toBe(true)
      expect(collection.models[1].get('selected')).toBe(false)
    })

    it('updates selection when changing selected model', () => {
      // Arrange
      collection.add({revision_id: 21})
      collection.add({revision_id: 37})
      view.setSelectedModelAndView(collection.models[0], collection.models[0].view)

      // Act
      view.setSelectedModelAndView(collection.models[1], collection.models[1].view)

      // Assert
      expect(collection.models[0].get('selected')).toBe(false)
      expect(collection.models[1].get('selected')).toBe(true)
    })
  })

  describe('pagination', () => {
    it('fetches previous page from collection', () => {
      // Arrange
      const fetchSpy = jest.spyOn(collection, 'fetch').mockResolvedValue()

      // Act
      view.prevPage()

      // Assert
      expect(fetchSpy).toHaveBeenCalledWith({
        page: 'prev',
        reset: true,
      })
    })

    it('fetches next page from collection', () => {
      // Arrange
      const fetchSpy = jest.spyOn(collection, 'fetch').mockResolvedValue()

      // Act
      view.nextPage()

      // Assert
      expect(fetchSpy).toHaveBeenCalledWith({
        page: 'next',
        reset: true,
      })
    })
  })

  describe('navigation state', () => {
    it('indicates when previous page is available', () => {
      // Arrange
      jest.spyOn(collection, 'canFetch').mockImplementation(arg => arg === 'prev')

      // Act & Assert
      expect(view.toJSON().CAN.FETCH_PREV).toBe(true)
    })

    it('indicates when next page is available', () => {
      // Arrange
      jest.spyOn(collection, 'canFetch').mockImplementation(arg => arg === 'next')

      // Act & Assert
      expect(view.toJSON().CAN.FETCH_NEXT).toBe(true)
    })
  })
})
