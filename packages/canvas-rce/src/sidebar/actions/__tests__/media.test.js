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
import * as actions from '../media'
import {
  fetchMedia,
  updateMediaObject,
  updateMediaObjectFailure,
  updateClosedCaptions,
} from '../../../rcs/fake'
import alertHandler from '../../../rce/alertHandler'

const sortBy = {sort: 'alphabetical', order: 'asc'}
const searchString = 'hello'

function getInitialState() {
  return {
    media: {
      course: {
        files: [],
        bookmark: null,
        isLoading: false,
        hasMore: true,
      },
    },
    contextType: 'course',
  }
}

describe('Media actions', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })
  describe('fetchMedia', () => {
    it('fetches initial page', () => {
      const dispatchSpy = jest.fn()
      const getState = getInitialState
      actions.fetchInitialMedia(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })
    it('fetches next page if necessary', () => {
      const dispatchSpy = jest.fn()
      const getState = getInitialState
      actions.fetchNextMedia(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })
    it('always fetches initial fetch page', () => {
      const dispatchSpy = jest.fn()
      const getState = () => {
        const state = getInitialState()
        state.media.course.hasMore = false
        state.media.course.isLoading = true
        state.media.course.files = [{one: '1'}, {two: '2'}, {three: '3'}]
        return state
      }
      actions.fetchInitialMedia(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })
    it('fetches if there is more to load', () => {
      const dispatchSpy = jest.fn()
      const getState = () => {
        const state = getInitialState()
        state.media.course.files = [{one: '1'}, {two: '2'}, {three: '3'}]
        state.media.course.hasMore = true
        return state
      }
      actions.fetchNextMedia(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalled()
    })
    it('does not fetch if requested but no more to load', () => {
      const dispatchSpy = jest.fn()
      const getState = () => {
        const state = getInitialState()
        state.media.course.files = [{one: '1'}, {two: '2'}, {three: '3'}]
        state.media.course.hasMore = false
        return state
      }
      actions.fetchNextMedia(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).not.toHaveBeenCalled()
    })
    it('fetches media', async () => {
      const fetchMediaSpy = jest.fn(fetchMedia)
      const dispatchSpy = jest.fn()
      const getState = () => {
        const state = getInitialState()
        state.source = {
          fetchMedia: fetchMediaSpy,
        }
        return state
      }
      await actions.fetchMedia(sortBy, searchString)(dispatchSpy, getState)
      expect(dispatchSpy).toHaveBeenCalledWith({
        type: actions.REQUEST_MEDIA,
        payload: {contextType: 'course'},
      })
      expect(fetchMediaSpy).toHaveBeenCalled()
    })
  })
  describe('requestInitialMedia', () => {
    it('returns the action object', () => {
      expect(actions.requestInitialMedia('course')).toEqual({
        type: actions.REQUEST_INITIAL_MEDIA,
        payload: {contextType: 'course'},
      })
    })
  })
  describe('requestMedia', () => {
    it('returns the action object', () => {
      expect(actions.requestMedia('course')).toEqual({
        type: actions.REQUEST_MEDIA,
        payload: {contextType: 'course'},
      })
    })
  })
  describe('receiveMedia', () => {
    it('returns the action object', () => {
      const fetchResponse = {
        files: [{one: 1}],
        bookmark: 'anotherurl',
      }
      expect(actions.receiveMedia({response: fetchResponse, contextType: 'course'})).toEqual({
        type: actions.RECEIVE_MEDIA,
        payload: {
          files: [{one: 1}],
          bookmark: 'anotherurl',
          contextType: 'course',
        },
      })
    })
  })
  describe('failMedia', () => {
    it('returns the action object', () => {
      expect(actions.failMedia({error: 'whoops', contextType: 'course'})).toEqual({
        type: actions.FAIL_MEDIA,
        payload: {
          error: 'whoops',
          contextType: 'course',
        },
      })
    })
  })
  describe('updateMediaObject', () => {
    const origAlertFunc = alertHandler.alertFunc
    beforeAll(() => {
      alertHandler.alertFunc = jest.fn()
    })
    afterAll(() => {
      alertHandler.alertFunc = origAlertFunc
    })

    it('calls the api', async () => {
      const updateSpy = jest.fn(updateMediaObject)
      const updateCCSpy = jest.fn()
      const dispatch = () => {}
      const getState = () => {
        const state = getInitialState()
        state.source = {updateMediaObject: updateSpy, updateClosedCaptions: updateCCSpy}
        return state
      }
      await actions.updateMediaObject({
        media_object_id: 'moid',
        title: 'title',
        subtitles: {en: 'whatever'},
      })(dispatch, getState)
      expect(updateSpy).toHaveBeenCalled()
      expect(updateSpy.mock.calls[0][1]).toEqual({
        attachment_id: undefined,
        media_object_id: 'moid',
        title: 'title',
      })
      expect(updateCCSpy).toHaveBeenCalled()
      expect(updateCCSpy.mock.calls[0][1]).toEqual({
        media_object_id: 'moid',
        subtitles: {en: 'whatever'},
      })
    })

    it('calls the api with attachment_id', async () => {
      const updateSpy = jest.fn(updateMediaObject)
      const updateCCSpy = jest.fn()
      const dispatch = () => {}
      const getState = () => {
        const state = getInitialState()
        state.source = {updateMediaObject: updateSpy, updateClosedCaptions: updateCCSpy}
        return state
      }
      await actions.updateMediaObject({
        attachment_id: '123',
        media_object_id: 'moid',
        title: 'title',
        subtitles: {en: 'whatever'},
      })(dispatch, getState)
      expect(updateSpy).toHaveBeenCalled()
      expect(updateSpy.mock.calls[0][1]).toEqual({
        attachment_id: '123',
        media_object_id: 'moid',
        title: 'title',
      })
      expect(updateCCSpy).toHaveBeenCalled()
      expect(updateCCSpy.mock.calls[0][1]).toEqual({
        attachment_id: '123',
        media_object_id: 'moid',
        subtitles: {en: 'whatever'},
      })
    })

    it('handles failure', async () => {
      const dispatch = () => {}
      const getState = () => {
        const state = getInitialState()
        state.source = {updateMediaObject: updateMediaObjectFailure, updateClosedCaptions}
        return state
      }
      try {
        await actions.updateMediaObject({media_object_id: 'moid', title: 'title'})(
          dispatch,
          getState,
        )
      } catch (e) {
        expect(alertHandler.alertFunc).toHaveBeenCalled()
      }
    })
  })
})
