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
          }, 10),
        ),
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

  test('load all finishes loading when all pages are loaded', async () => {
    const linkHeader =
      '<store-url?page=5>; rel="current",' +
      '<store-url?page=4>; rel="prev",' +
      '<store-url?page=1>; rel="first",' +
      '<store-url?page=5>; rel="last"'

    jest.spyOn($, 'ajax').mockImplementation(() => {
      return {
        then: (success, _failure) => {
          success([], 'success', {getResponseHeader: () => linkHeader})
          return Promise.resolve()
        },
      }
    })
    await store.loadAll({})
    expect(store.getState()['{}'].loading).toBe(false)
  })

  test('load does not finish loading until all pages are loaded', async () => {
    let page = 1
    const linkHeader = () => {
      let headers = `<store-url?page=${page}>; rel="current", `
      if (page > 1) headers += `<store-url?page=${page - 1}>; rel="prev", `
      if (page < 5) headers += `<store-url?page=${page + 1}>; rel="next", `
      headers += `<store-url?page=1>; rel="first", <store-url?page=5>; rel="last"`
      page++
      expect(store.getState()['{}'].loading).toBe(true)
      return headers
    }

    jest.spyOn($, 'ajax').mockImplementation(() => {
      return {
        abort: () => {},
        then: (success, _failure) => {
          success([], 'success', {getResponseHeader: linkHeader})
          return Promise.resolve()
        },
      }
    })

    await store.loadAll({})
    setTimeout(() => {
      // Wait for event loop to tick so inner promises resolve
      expect(store.getState()['{}'].loading).toBe(false)
    }, 0)
  })
})
