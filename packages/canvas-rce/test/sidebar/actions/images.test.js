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

import assert from 'assert'
import sinon from 'sinon'
import * as actions from '../../../src/sidebar/actions/images'

const sortBy = {sort: 'alphabetical', order: 'asc'}
const searchString = 'hello'

describe('Image dispatch shapes', () => {
  describe('receiveImages', () => {
    const contextType = 'course'
    const response = {
      bookmark: 'p2',
      files: [],
      searchString: 'panda'
    }

    it('returns a type of RECEIVE_IMAGES', () => {
      const {type} = actions.receiveImages({response, contextType})
      assert(type === actions.RECEIVE_IMAGES)
    })

    describe('returning a payload', () => {
      it('includes contextType', () => {
        const {payload} = actions.receiveImages({response, contextType})
        assert(payload.contextType === 'course')
      })

      it('includes files', () => {
        const {payload} = actions.receiveImages({response})
        assert.deepEqual(payload.files, [])
      })

      it('includes bookmark', () => {
        const {payload} = actions.receiveImages({response})
        assert(payload.bookmark === 'p2')
      })

      it('includes searchString', () => {
        const {payload} = actions.receiveImages({response})
        assert(payload.searchString === 'panda')
      })
    })

    describe('when the "category" is set to "buttons_and_icons', () => {
      let buttonAndIconsResponse, opts

      const subject = () => actions.receiveImages(buttonAndIconsResponse)

      beforeEach(() => {
        buttonAndIconsResponse = {
          response: {
            files: [{id: 1}, {id: 2}, {id: 3}]
          },
          contextType,
          opts: {
            category: 'buttons_and_icons'
          }
        }
      })

      it('applies the buttons and icons attribute to each file', () => {
        assert.deepEqual(
          subject().payload.files.map(f => f['data-inst-buttons-and-icons']),
          [true, true, true]
        )
      })
    })
  })
})

describe('Image actions', () => {
  describe('createAddImage', () => {
    it('has the right action type', () => {
      const action = actions.createAddImage({}, 'course')
      assert(action.type === actions.ADD_IMAGE)
    })

    it('includes id from first param', () => {
      const id = 47
      const action = actions.createAddImage({id}, 'course')
      assert(action.payload.newImage.id === id)
    })

    it('includes filename from first param', () => {
      const filename = 'foo'
      const action = actions.createAddImage({filename}, 'course')
      assert(action.payload.newImage.filename === filename)
    })

    it('includes display_name from first param', () => {
      const display_name = 'bar'
      const action = actions.createAddImage({display_name}, 'course')
      assert(action.payload.newImage.display_name === display_name)
    })

    it('includes preview_url from first param', () => {
      const url = 'some_url'
      const action = actions.createAddImage({url}, 'course')
      assert(action.payload.newImage.preview_url === url)
    })

    it('includes thumbnail_url from first param', () => {
      const thumbnail_url = 'other_url'
      const action = actions.createAddImage({thumbnail_url}, 'course')
      assert(action.payload.newImage.thumbnail_url === thumbnail_url)
    })
  })

  describe('fetchImages', () => {
    it('fetches initial page if necessary, part 1', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          images: {
            user: {
              files: [],
              bookmark: null,
              hasMore: true,
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchInitialImages(sortBy, searchString)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })

    it('sends specified options', () => {
      const fetchImageStub = sinon.stub()
      fetchImageStub.returns(new Promise((res, rej) => res({})))

      const dispatch = fn => {
        if (typeof fn === 'function') {
          fn(dispatch, getState)
        }
      }

      const getState = () => {
        return {
          source: {
            fetchImages: fetchImageStub
          },
          images: {
            user: {
              files: [],
              bookmark: null,
              hasMore: true,
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchInitialImages({category: 'uncategorized'})(dispatch, getState)
      assert.equal(fetchImageStub.firstCall.args[0].category, 'uncategorized')
    })

    it('fetches initial page if necessary, part 2', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          images: {
            user: {
              files: [],
              bookmark: null,
              hasMore: true,
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })

    it('sends specified options', () => {
      const fetchImageStub = sinon.stub()
      fetchImageStub.returns(new Promise((res, rej) => res({})))

      const dispatch = fn => {
        if (typeof fn === 'function') {
          fn(dispatch, getState)
        }
      }

      const getState = () => {
        return {
          source: {
            fetchImages: fetchImageStub
          },
          images: {
            user: {
              files: [],
              bookmark: null,
              hasMore: true,
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextImages({category: 'uncategorized'})(dispatch, getState)
      assert.equal(fetchImageStub.firstCall.args[0].category, 'uncategorized')
    })

    it('skips the fetch if currently loading', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          images: {
            user: {
              files: [{one: '1'}, {two: '2'}, {three: '3'}],
              bookmark: 'someurl',
              hasMore: true,
              isLoading: true
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      assert(!dispatchSpy.called)
    })

    it('fetches if requested and there are more to load', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          images: {
            user: {
              files: [{one: '1'}, {two: '2'}, {three: '3'}],
              hasMore: true,
              bookmark: 'someurl',
              isLoading: false
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })

    it('does not fetch if requested but no more to load', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        return {
          images: {
            user: {
              files: [{one: '1'}, {two: '2'}, {three: '3'}],
              hasMore: false,
              bookmark: 'someurl',
              isLoading: false,
              requested: true
            }
          },
          contextType: 'user'
        }
      }
      actions.fetchNextImages(sortBy, searchString)(dispatchSpy, getState)
      assert(!dispatchSpy.called)
    })
  })
})
