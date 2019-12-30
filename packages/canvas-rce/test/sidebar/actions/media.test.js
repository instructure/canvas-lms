/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import * as actions from '../../../src/sidebar/actions/media'
import {
  fetchMedia,
  updateMediaObject,
  updateMediaObjectFailure
} from '../../../src/sidebar/sources/fake'
import alertHandler from '../../../src/rce/alertHandler'

const sortBy = {sort: 'alphabetical', order: 'asc'}

function getInitialState() {
  return {
    media: {
      course: {
        files: [],
        bookmark: null,
        isLoading: false,
        hasMore: true
      }
    },
    contextType: 'course'
  }
}
describe('Media actions', () => {
  afterEach(() => {
    sinon.restore()
  })
  describe('fetchMedia', () => {
    it('fetches initial page', () => {
      const dispatchSpy = sinon.spy()
      const getState = getInitialState
      actions.fetchInitialMedia(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('fetches next page if necessary', () => {
      const dispatchSpy = sinon.spy()
      const getState = getInitialState
      actions.fetchNextMedia(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('always fetches initial fetch page', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        const state = getInitialState()
        state.media.course.hasMore = false
        state.media.course.isLoading = true
        state.media.course.files = [{one: '1'}, {two: '2'}, {three: '3'}]
        return state
      }
      actions.fetchInitialMedia(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('fetches if there is more to load', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        const state = getInitialState()
        state.media.course.files = [{one: '1'}, {two: '2'}, {three: '3'}]
        state.media.course.hasMore = true
        return state
      }
      actions.fetchNextMedia(sortBy)(dispatchSpy, getState)
      assert(dispatchSpy.called)
    })
    it('does not fetch if requested but no more to load', () => {
      const dispatchSpy = sinon.spy()
      const getState = () => {
        const state = getInitialState()
        state.media.course.files = [{one: '1'}, {two: '2'}, {three: '3'}]
        state.media.course.hasMore = false
        return state
      }
      actions.fetchNextMedia(sortBy)(dispatchSpy, getState)
      assert(!dispatchSpy.called)
    })
    it('fetches media', async () => {
      const fetchMediaSpy = sinon.spy(fetchMedia)
      const dispatchSpy = sinon.spy()
      const getState = () => {
        const state = getInitialState()
        state.source = {
          fetchMedia: fetchMediaSpy
        }
        return state
      }
      await actions.fetchMedia(sortBy)(dispatchSpy, getState)
      assert(
        dispatchSpy.calledWith({type: actions.REQUEST_MEDIA, payload: {contextType: 'course'}})
      )
      assert(fetchMediaSpy.called)
    })
  })
  describe('requestInitialMedia', () => {
    it('returns the action object', () => {
      assert.deepEqual(actions.requestInitialMedia('course'), {
        type: actions.REQUEST_INITIAL_MEDIA,
        payload: {contextType: 'course'}
      })
    })
  })
  describe('requestMedia', () => {
    it('returns the action object', () => {
      assert.deepEqual(actions.requestMedia('course'), {
        type: actions.REQUEST_MEDIA,
        payload: {contextType: 'course'}
      })
    })
  })
  describe('receiveMedia', () => {
    it('returns the action object', () => {
      const fetchResponse = {
        files: [{one: 1}],
        bookmark: 'anotherurl'
      }
      assert.deepEqual(actions.receiveMedia({response: fetchResponse, contextType: 'course'}), {
        type: actions.RECEIVE_MEDIA,
        payload: {
          files: [{one: 1}],
          bookmark: 'anotherurl',
          contextType: 'course'
        }
      })
    })
  })
  describe('failMedia', () => {
    it('returns the action object', () => {
      assert.deepEqual(actions.failMedia({error: 'whoops', contextType: 'course'}), {
        type: actions.FAIL_MEDIA,
        payload: {
          error: 'whoops',
          contextType: 'course'
        }
      })
    })
  })
  describe('updateMediaObject', () => {
    const origAlertFunc = alertHandler.alertFunc
    before(() => {
      alertHandler.alertFunc = sinon.spy()
    })
    after(() => {
      alertHandler.alertFunc = origAlertFunc
    })
    it('calls the api', async () => {
      const updateSpy = sinon.spy(updateMediaObject)
      const dispatch = () => {}
      const getState = () => {
        const state = getInitialState()
        state.source = {updateMediaObject: updateSpy}
        return state
      }
      await actions.updateMediaObject({media_object_id: 'moid', title: 'title'})(dispatch, getState)
      assert(updateSpy.called)
      assert.deepEqual(updateSpy.getCalls()[0].args[1], {
        media_object_id: 'moid',
        title: 'title'
      })
    })
    it('handles failure', async () => {
      const dispatch = () => {}
      const getState = () => {
        const state = getInitialState()
        state.source = {updateMediaObject: updateMediaObjectFailure}
        return state
      }
      try {
        await actions.updateMediaObject({media_object_id: 'moid', title: 'title'})(
          dispatch,
          getState
        )
      } catch (e) {
        assert(alertHandler.alertFunc.called)
      }
    })
  })
})
