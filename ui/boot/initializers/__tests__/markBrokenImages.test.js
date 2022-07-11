//
// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import fetchMock from 'fetch-mock'
import {attachErrorHandler, getImagesAndAttach} from '../markBrokenImages'

function setAttrs(elem, id, src, alt) {
  elem.id = id
  elem.src = src
  elem.alt = alt
}

const flushPromises = () => new Promise(setTimeout)

describe('markBrokenImages::', () => {
  let div

  beforeAll(() => {
    div = document.createElement('div')
    document.body.append(div)
  })

  afterAll(() => {
    div && div.remove()
    div = undefined
  })

  describe('attachErrorHandler', () => {
    let img

    beforeEach(() => {
      img = document.createElement('img')
      setAttrs(img, 'borked', 'broken_img.jpg', 'broken')
      div.append(img)
    })

    afterEach(() => {
      img && img.remove()
      img = undefined
    })

    it('attaches proper class to images when they are broken but not locked', async () => {
      fetchMock.getOnce('end:/broken_img.jpg', 404, {overwriteRoutes: true})
      attachErrorHandler(img)
      expect(img.classList.contains('broken-image')).toBe(false)
      const error = new Event('error')
      img.dispatchEvent(error)
      await flushPromises()
      expect(img.classList.contains('broken-image')).toBe(true)
    })

    it('changes src when the image is locked', async () => {
      fetchMock.getOnce('end:/broken_img.jpg', 403, {overwriteRoutes: true})
      attachErrorHandler(img)
      img.dispatchEvent(new Event('error'))
      await flushPromises()
      expect(img.src).toMatch('/images/svg-icons/icon_lock.svg')
    })

    it('sets appropriate alt text indicating the image is locked', async () => {
      fetchMock.getOnce('end:/broken_img.jpg', 403, {overwriteRoutes: true})
      attachErrorHandler(img)
      img.dispatchEvent(new Event('error'))
      await flushPromises()
      expect(img.alt).toBe('Locked image')
    })
  })

  describe('getImagesAndAttach', () => {
    let img1
    let img2

    beforeEach(() => {
      img1 = document.createElement('img')
      img2 = document.createElement('img')
      setAttrs(img1, 'borked', 'broken_image.jpg', 'broken')
      setAttrs(img2, 'empty_src', '', 'empty_src')
      div.append(img1)
      div.append(img2)
    })

    afterEach(() => {
      while (div.lastElementChild) {
        div.removeChild(div.lastElementChild)
      }
      img1 = undefined
      img2 = undefined
    })

    // if the image error handler is actually triggered, and the fetch that it issues
    // returns a 404, then all code paths in the handler add the broken-image class
    // to the image. So if that class is present, then the error handler was called,
    // which means it was attached. Otherwise, the error handler was not attached.
    it('attaches error handlers only to elements with a non-empty src', async () => {
      fetchMock.getOnce('end:/broken_image.jpg', 404, {overwriteRoutes: true})
      getImagesAndAttach()
      img1.dispatchEvent(new Event('error'))
      img2.dispatchEvent(new Event('error'))
      await flushPromises()
      expect(img1.classList.contains('broken-image')).toBe(true)
      expect(img2.classList.contains('broken-image')).toBe(false)
    })
  })
})
