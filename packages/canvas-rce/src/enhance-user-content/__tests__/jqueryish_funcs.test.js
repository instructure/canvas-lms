/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {closest, hide, show, setData, getData, insertAfter} from '../jqueryish_funcs'

describe('jqueryish_funcs', () => {
  let testme
  beforeEach(() => {
    document.body.innerHTML = '<div id="testme"></div>'
    testme = document.getElementById('testme')
  })

  // because jsdom doesn't actually render anything
  // the div's offsetWidth and height will always
  // be 0 so hidden will always return true visible
  // will return false and we can't test using jest

  describe('closest', () => {
    let start_elem, the_button
    beforeEach(() => {
      document.getElementById('testme').innerHTML = `
      <div><button id="the_button"><span id="start_elem">hello</span></button></div>
      `
      start_elem = document.getElementById('start_elem')
      the_button = document.getElementById('the_button')
    })

    it('finds the closest matching element', () => {
      expect(closest(start_elem, 'button', testme)).toBe(the_button)
    })

    it('returns null if not found', () => {
      expect(closest(start_elem, 'div.nope', testme)).toBeNull()
    })

    it('works without the context arg', () => {
      expect(closest(start_elem, 'button')).toBe(the_button)
    })
  })

  describe('hide', () => {
    it('hides the element', () => {
      testme.style.display = 'block'
      expect(testme.style.display).toEqual('block')
      hide(testme)
      expect(testme.style.display).toEqual('none')
    })
  })

  describe('show', () => {
    it('shows a previously hidden element', () => {
      testme.style.display = 'block'
      expect(testme.style.display).toEqual('block')
      hide(testme)
      show(testme)
      expect(testme.style.display).toEqual('block')
    })
  })

  describe('setData', () => {
    it('hangs a data obj off the elem for the data', () => {
      setData(testme, 'foo', 'bar')
      expect(testme.data).not.toBeUndefined()
      expect(testme.data.foo).toEqual('bar')
    })
  })

  describe('getData', () => {
    it('gets data set by setData', () => {
      setData(testme, 'foo', 'bar')
      expect(getData(testme, 'foo')).toEqual('bar')
    })

    it('get can get data from a data- attribute', () => {
      testme.setAttribute('data-foo', 'bar')
      expect(getData(testme, 'foo')).toEqual('bar')
    })
  })

  describe('insertAfter', () => {
    it('inserts an element after the reference element', () => {
      const new_elem = document.createElement('div')
      new_elem.setAttribute('class', 'i-am-new')
      insertAfter(new_elem, testme)
      expect(document.body.innerHTML).toEqual('<div id="testme"></div><div class="i-am-new"></div>')
    })
  })
})
