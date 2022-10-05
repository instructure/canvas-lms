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

import createStore from '../createStore'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'

describe('account course user search createStore', () => {
  let store

  beforeEach(() => {
    store = createStore({getUrl: () => 'store-url'})
  })

  test('load aborts previous load request', () => {
    jest.spyOn($.ajaxJSON, 'abortRequest').mockImplementation()
    jest.spyOn($, 'ajax').mockImplementation(
      () =>
        new Promise((resolve, reject) =>
          setTimeout(() => {
            reject(new Error('should never get here because it should have been aborted'))
          }, 10)
        )
    )
    store.load({})
    store.load({})
    expect($.ajaxJSON.abortRequest).toHaveBeenCalledTimes(2)
    expect($.ajaxJSON.abortRequest).toHaveBeenNthCalledWith(1, undefined)
    expect($.ajaxJSON.abortRequest).toHaveBeenNthCalledWith(2, Promise.resolve({}))
  })

  test('load does not set the error flag if the request is aborted', () => {
    jest.spyOn($, 'ajax').mockRejectedValue({})
    store.load({})
    expect(store.getState()['{}'].error).toBeUndefined()
  })

  test('load sets the error flag on non-abort failures', () => {
    jest.spyOn($, 'ajax').mockImplementation(() => {
      return {
        then: (success, failure) => failure({}, 'error'),
      }
    })

    store.load({})
    expect(store.getState()['{}'].error).toBe(true)
  })
})
