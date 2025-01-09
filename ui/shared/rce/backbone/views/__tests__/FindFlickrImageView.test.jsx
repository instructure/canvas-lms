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
import FindFlickrImageView from '../FindFlickrImageView'
import {waitFor} from '@testing-library/dom'

// Mock jQuery's disableWhileLoading and AJAX
$.fn.disableWhileLoading = function (promise) {
  promise.then(() => this.trigger('loaded'))
  return this
}

$.getJSON = (url, callback) => {
  return new Promise(resolve => {
    callback({photos: {photo: photoData}})
    resolve()
  })
}

const searchTerm = 'bunnies'
const photoData = [
  {
    id: 'noooooo',
    secret: 'whyyyyy',
    farm: 'moooo',
    owner: 'notyou',
    server: 'maneframe',
    needs_interstitial: 0,
  },
  {
    id: 'nooope',
    secret: 'sobbbbb',
    farm: 'sadface',
    owner: 'meeee',
    server: 'mwhahahah',
    needs_interstitial: 0,
  },
  {
    id: 'nsfwid',
    secret: 'nsfwsecret',
    farm: 'nsfwfarm',
    owner: 'nsfwowner',
    server: 'nsfwserver',
    needs_interstitial: 1,
  },
]

describe('FindFlickrImageView', () => {
  let view
  let server
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)

    server = jest.spyOn(global, 'fetch').mockImplementation(url => {
      if (url.includes(searchTerm)) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({photos: {photo: photoData}}),
        })
      }
      return Promise.reject(new Error('Not found'))
    })

    view = new FindFlickrImageView()
    view.flickrUrl = '/mock_flickr'
    view.render().$el.appendTo(container)
  })

  afterEach(() => {
    server.mockRestore()
    container.remove()
  })

  describe('rendering', () => {
    it('renders the form with search elements', () => {
      const form = container.querySelector('form.FindFlickrImageView')
      expect(form).toBeInTheDocument()
      expect(form).toBeVisible()

      const input = form.querySelector('input.flickrSearchTerm')
      expect(input).toBeInTheDocument()
      expect(input).toBeVisible()

      const button = form.querySelector('button[type="submit"]')
      expect(button).toBeInTheDocument()
      expect(button).toBeVisible()
    })
  })

  describe('search functionality', () => {
    it('displays non-nsfw images in search results', async () => {
      const form = container.querySelector('form.FindFlickrImageView')
      const input = form.querySelector('input.flickrSearchTerm')
      const resultsContainer = container.querySelector('.flickrResults')

      // Set search term and submit
      $(input).val(searchTerm)
      $(form).submit()

      // Wait for results to be displayed
      await waitFor(() => {
        expect(resultsContainer.innerHTML).toContain('thumbnail')
      })

      const results = container.querySelectorAll('ul.flickrResults li a.thumbnail')
      expect(results).toHaveLength(2)

      // Verify image attributes for non-nsfw results
      results.forEach((result, idx) => {
        expect(result.getAttribute('data-fullsize')).toContain(photoData[idx].id)
        expect(result.getAttribute('data-fullsize')).toContain(photoData[idx].secret)
        expect(result.getAttribute('data-fullsize')).toContain(photoData[idx].farm)
        expect(result.getAttribute('data-fullsize')).toContain(photoData[idx].server)
        expect(result.getAttribute('data-linkto')).toContain(photoData[idx].id)
        expect(result.getAttribute('data-linkto')).toContain(photoData[idx].owner)
      })
    })

    it('filters out nsfw images from search results', async () => {
      const form = container.querySelector('form.FindFlickrImageView')
      const input = form.querySelector('input.flickrSearchTerm')
      const resultsContainer = container.querySelector('.flickrResults')

      // Set search term and submit
      $(input).val(searchTerm)
      $(form).submit()

      // Wait for results and verify NSFW image is not included
      await waitFor(() => {
        expect(resultsContainer.innerHTML).toContain('thumbnail')
      })

      const results = container.querySelectorAll('ul.flickrResults li a.thumbnail')
      const nsfwImage = Array.from(results).find(result =>
        result.getAttribute('data-fullsize').includes('nsfwid'),
      )
      expect(nsfwImage).toBeUndefined()
    })
  })
})
