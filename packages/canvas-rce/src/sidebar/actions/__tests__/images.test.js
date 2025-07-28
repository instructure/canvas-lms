/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as actions from '../images'
import {ICON_MAKER_ICONS} from '../../../rce/plugins/instructure_icon_maker/svg/constants'

const sortBy = {sort: 'alphabetical', order: 'asc'}
const searchString = 'hello'

describe('Image dispatch shapes', () => {
  describe('receiveImages', () => {
    const contextType = 'course'
    const response = {
      bookmark: 'p2',
      files: [],
      searchString: 'panda',
    }

    it('returns a type of RECEIVE_IMAGES', () => {
      const {type} = actions.receiveImages({response, contextType})
      expect(type).toBe(actions.RECEIVE_IMAGES)
    })

    describe('returning a payload', () => {
      it('includes contextType', () => {
        const {payload} = actions.receiveImages({response, contextType})
        expect(payload.contextType).toBe('course')
      })

      it('includes files', () => {
        const {payload} = actions.receiveImages({response})
        expect(payload.files).toEqual([])
      })

      it('includes bookmark', () => {
        const {payload} = actions.receiveImages({response})
        expect(payload.bookmark).toBe('p2')
      })

      it('includes searchString', () => {
        const {payload} = actions.receiveImages({response})
        expect(payload.searchString).toBe('panda')
      })
    })

    describe('when the "category" is set to "icon_maker_icons', () => {
      let iconMakerResponse

      const subject = () => actions.receiveImages(iconMakerResponse)

      beforeEach(() => {
        iconMakerResponse = {
          response: {
            files: [
              {id: 1, download_url: 'https://canvas.instructure.com/files/1/download'},
              {id: 2, download_url: 'https://canvas.instructure.com/files/2/download'},
              {id: 3, download_url: 'https://canvas.instructure.com/files/3/download'},
            ],
          },
          contextType,
          opts: {
            category: ICON_MAKER_ICONS,
          },
        }
      })

      it('applies the icon maker attribute to each file', () => {
        expect(subject().payload.files.map(f => f['data-inst-icon-maker-icon'])).toEqual([
          true,
          true,
          true,
        ])
      })

      it('applies the download url data attribute', () => {
        expect(subject().payload.files.map(f => f['data-download-url'])).toEqual([
          'https://canvas.instructure.com/files/1/download?icon_maker_icon=1',
          'https://canvas.instructure.com/files/2/download?icon_maker_icon=1',
          'https://canvas.instructure.com/files/3/download?icon_maker_icon=1',
        ])
      })
    })
  })
})

describe('Image actions', () => {
  describe('createAddImage', () => {
    it('has the right action type', () => {
      const action = actions.createAddImage({}, 'course')
      expect(action.type).toBe(actions.ADD_IMAGE)
    })

    it('includes id from first param', () => {
      const id = 47
      const action = actions.createAddImage({id}, 'course')
      expect(action.payload.newImage.id).toBe(id)
    })

    it('includes filename from first param', () => {
      const filename = 'foo'
      const action = actions.createAddImage({filename}, 'course')
      expect(action.payload.newImage.filename).toBe(filename)
    })

    it('includes display_name from first param', () => {
      const display_name = 'bar'
      const action = actions.createAddImage({display_name}, 'course')
      expect(action.payload.newImage.display_name).toBe(display_name)
    })

    it('includes preview_url from first param', () => {
      const url = 'some_url'
      const action = actions.createAddImage({url}, 'course')
      expect(action.payload.newImage.preview_url).toBe(url)
    })

    it('includes thumbnail_url from first param', () => {
      const thumbnail_url = 'other_url'
      const action = actions.createAddImage({thumbnail_url}, 'course')
      expect(action.payload.newImage.thumbnail_url).toBe(thumbnail_url)
    })
  })

  describe('fetchImages', () => {
    it('fetches initial page if necessary, part 1', () => {
      const dispatchSpy = jest.fn()
      const getState = () => ({
        images: {
          user: {
            files: [],
            bookmark: null,
            hasMore: true,
            isLoading: false,
          },
        },
        contextType: 'user',
      })
      actions.fetchInitialImages(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })

    it('sends specified options', () => {
      const fetchImageStub = jest.fn().mockResolvedValue({})

      const dispatch = fn => {
        if (typeof fn === 'function') {
          fn(dispatch, getState)
        }
      }

      const getState = () => ({
        source: {
          fetchImages: fetchImageStub,
        },
        images: {
          user: {
            files: [],
            bookmark: null,
            hasMore: true,
            isLoading: false,
          },
        },
        contextType: 'user',
      })
      actions.fetchInitialImages({category: 'uncategorized'})(dispatch, getState)
      expect(fetchImageStub.mock.calls[0][0].category).toBe('uncategorized')
    })

    it('fetches initial page if necessary, part 2', () => {
      const dispatchSpy = jest.fn()
      const getState = () => ({
        images: {
          user: {
            files: [],
            bookmark: null,
            hasMore: true,
            isLoading: false,
          },
        },
        contextType: 'user',
      })
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })

    it('sends specified options for next images', () => {
      const fetchImageStub = jest.fn().mockResolvedValue({})

      const dispatch = fn => {
        if (typeof fn === 'function') {
          fn(dispatch, getState)
        }
      }

      const getState = () => ({
        source: {
          fetchImages: fetchImageStub,
        },
        images: {
          user: {
            files: [],
            bookmark: null,
            hasMore: true,
            isLoading: false,
          },
        },
        contextType: 'user',
      })
      actions.fetchNextImages({category: 'uncategorized'})(dispatch, getState)
      expect(fetchImageStub.mock.calls[0][0].category).toBe('uncategorized')
    })

    it('skips the fetch if currently loading', () => {
      const dispatchSpy = jest.fn()
      const getState = () => ({
        images: {
          user: {
            files: [],
            bookmark: null,
            hasMore: true,
            isLoading: true,
          },
        },
        contextType: 'user',
      })
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).not.toHaveBeenCalled()
    })

    it('fetches if requested and there are more to load', () => {
      const dispatchSpy = jest.fn()
      const getState = () => ({
        images: {
          user: {
            files: [],
            bookmark: 'someurl',
            hasMore: true,
            isLoading: false,
          },
        },
        contextType: 'user',
      })
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })

    it('does not fetch if requested but no more to load', () => {
      const dispatchSpy = jest.fn()
      const getState = () => ({
        images: {
          user: {
            files: [],
            bookmark: null,
            hasMore: false,
            isLoading: false,
          },
        },
        contextType: 'user',
      })
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).not.toHaveBeenCalled()
    })
  })
})
