/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import JQuerySelectorCache from '../JQuerySelectorCache'
import sinon from 'sinon'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const strictEqual = (x, y) => expect(x).toStrictEqual(y)

describe('JQuerySelectorCache', () => {
  let selectorCache
  let fixtures

  beforeEach(() => {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="foo">testing!</div>'
    selectorCache = new JQuerySelectorCache()
  })

  afterEach(() => {
    fixtures.innerHTML = ''
  })

  describe('#get', () => {
    test('returns a jquery selector', () => {
      const response = selectorCache.get('#foo')
      strictEqual(response instanceof $, true)
    })

    test('returns the selector for the given element', () => {
      const response = selectorCache.get('#foo')
      strictEqual(response.text(), 'testing!')
    })

    test('returns a valid selector even if the element does not exist', () => {
      const response = selectorCache.get('#does_not_exist')
      strictEqual(response.length, 0)
    })

    test('reuses the cached value on subsequent requests', () => {
      const first = selectorCache.get('#foo')
      const second = selectorCache.get('#foo')
      strictEqual(first, second)
    })
  })

  describe('#set', () => {
    test('caches the value that subsequent `get` calls will use', () => {
      selectorCache.set('#foo')
      sinon.stub(selectorCache, 'set')
      selectorCache.get('#foo')
      // we verify the `get` call uses the cached value
      // by asserting that `set` is not called
      strictEqual(selectorCache.set.callCount, 0)
    })

    test('stores the appropriate selector for the given value', () => {
      selectorCache.set('#foo')
      const value = selectorCache.get('#foo')
      strictEqual(value.text(), 'testing!')
    })
  })
})
