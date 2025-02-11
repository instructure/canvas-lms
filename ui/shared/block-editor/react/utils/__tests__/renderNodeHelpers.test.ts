/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {getToolbarPos} from '../renderNodeHelpers'

const createDOM = () => {
  const mountPoint = document.createElement('div')
  mountPoint.style.width = '300px'
  mountPoint.style.height = '150px'
  document.body.appendChild(mountPoint)
  // @ts-expect-error
  mountPoint.getBoundingClientRect = jest.fn(() => ({top: 0, left: 0, width: 300, height: 300}))

  const topbar = document.createElement('div')
  topbar.className = 'topbar'
  document.body.appendChild(topbar)
  // @ts-expect-error
  topbar.getBoundingClientRect = jest.fn(() => ({bottom: 100}))

  const domNode = document.createElement('div')
  domNode.style.position = 'relative'
  domNode.style.left = '16px'
  domNode.style.top = '16px'
  domNode.style.width = '100px'
  domNode.style.height = '100px'
  mountPoint.appendChild(domNode)
  // @ts-expect-error
  domNode.getBoundingClientRect = jest.fn(() => ({top: 200, left: 50, width: 100, height: 100}))

  return {mountPoint, domNode, topbar}
}

const createToolbar = (mountPoint: HTMLElement) => {
  const theToolbar = document.createElement('div')
  theToolbar.style.position = 'absolute'
  theToolbar.style.width = '75px'
  theToolbar.style.height = '25px'
  mountPoint.appendChild(theToolbar)
  // @ts-expect-error
  theToolbar.getBoundingClientRect = jest.fn(() => ({top: 0, left: 0, width: 75, height: 25}))
  return theToolbar
}

describe('renderNodeHelpers', () => {
  describe('getToolbarPos', () => {
    it('returns the correct position', () => {
      const {mountPoint, domNode} = createDOM()
      const theToolbar = createToolbar(mountPoint)

      const result = getToolbarPos(domNode, mountPoint, theToolbar)
      expect(result).toEqual({top: 170, left: 45})
    })

    it('returns the correct position without an offset', () => {
      const {mountPoint, domNode} = createDOM()
      const theToolbar = createToolbar(mountPoint)

      const result = getToolbarPos(domNode, mountPoint, theToolbar, false)
      expect(result).toEqual({top: 200, left: 50})
    })

    it('returns the correct position without a vertical offset if the toolbar is not present', () => {
      const {mountPoint, domNode} = createDOM()

      const result = getToolbarPos(domNode, mountPoint, null, true)
      expect(result).toEqual({top: 200, left: 45})
    })

    it('returns 0, 0 if domNode is null', () => {
      const {mountPoint} = createDOM()
      const theToolbar = createToolbar(mountPoint)

      const result = getToolbarPos(null, mountPoint, theToolbar)
      expect(result).toEqual({top: 0, left: 0})
    })

    it('moves toolbar below node when it would overlap with topbar', () => {
      const {mountPoint, domNode} = createDOM()
      const theToolbar = createToolbar(mountPoint)

      // @ts-expect-error
      domNode.getBoundingClientRect = jest.fn(() => ({top: 75, left: 50, width: 100, height: 100}))

      const result = getToolbarPos(domNode, mountPoint, theToolbar)
      expect(result).toEqual({top: 175, left: 45})
    })
  })
})
