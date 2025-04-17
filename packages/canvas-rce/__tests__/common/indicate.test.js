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

const sinon = require('sinon/pkg/sinon.js')

import indicate from '../../src/common/indicate'

describe('indicate function', () => {
  let clock, region, margin, indicator

  beforeEach(() => {
    clock = sinon.useFakeTimers()
    region = {
      top: 10,
      left: 20,
      width: 30,
      height: 40,
      zIndex: 50,
    }
    margin = 5
    indicator = indicate(region, margin)
  })

  afterEach(() => {
    clock.restore()
  })

  it('appends a div to the body', () => {
    expect(indicator.parentNode).toEqual(document.body)
  })

  it('removes the div after 2 seconds', () => {
    clock.tick(2000)
    expect(indicator.parentNode).toBeNull()
  })

  describe('shape', () => {
    it('has dimensions of region plus margin', () => {
      expect(indicator.style.width).toEqual('40px')
      expect(indicator.style.height).toEqual('50px')
    })

    it('is positioned at region minus margin', () => {
      expect(indicator.style.top).toEqual('5px')
      expect(indicator.style.left).toEqual('15px')
    })

    it('has a default margin of 3', () => {
      region.left = 3
      expect(indicate(region).style.left).toEqual('0px')
    })
  })

  describe('transitions', () => {
    it('div initially has enter and active classes', () => {
      expect(/enter/.test(indicator.className)).toBeTruthy()
      expect(/active/.test(indicator.className)).toBeTruthy()
    })

    it('div has leave class after 900ms', () => {
      clock.tick(900)
      expect(/leave/.test(indicator.className)).toBeTruthy()
    })

    it('div gets leave fast class on mouse over', () => {
      indicator.dispatchEvent(new window.MouseEvent('mouseover'))
      expect(/leaveFast/.test(indicator.className)).toBeTruthy()
    })
  })
})
