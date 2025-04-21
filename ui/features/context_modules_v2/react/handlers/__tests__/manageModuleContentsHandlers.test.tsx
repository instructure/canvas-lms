/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {defaultModuleItems, defaultModules} from './dataMocks'
import {
  createTopOrder,
  createBottomOrder,
  createBeforeOrder,
  createAfterOrder,
  createModuleItemOrder,
  createModuleContentsOrder,
  createModuleOrder,
  getErrorMessage,
  getTrayTitle,
} from '../manageModuleContentsHandlers'

describe('manageModuleContentsHandlers', () => {
  describe('createTopOrder', () => {
    it('should return the correct order', () => {
      const itemToMove = '5'
      const result = createTopOrder(itemToMove, defaultModuleItems)
      expect(result).toEqual(['5', '0', '1', '2', '3', '4', '6', '7', '8', '9'])
    })

    it('when itemToMove is not in items', () => {
      const itemToMove = '10'
      const result = createTopOrder(itemToMove, defaultModuleItems)
      expect(result).toEqual(['10', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
    })
  })

  describe('createBottomOrder', () => {
    it('should return the correct order', () => {
      const itemToMove = '5'
      const result = createBottomOrder(itemToMove, defaultModuleItems)
      expect(result).toEqual(['0', '1', '2', '3', '4', '6', '7', '8', '9', '5'])
    })

    it('when itemToMove is not in items', () => {
      const itemToMove = '10'
      const result = createBottomOrder(itemToMove, defaultModuleItems)
      expect(result).toEqual(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'])
    })
  })

  describe('createBeforeOrder', () => {
    it('should return the correct order', () => {
      const itemToMove = '1'
      const referenceId = '5'
      const result = createBeforeOrder(itemToMove, defaultModuleItems, referenceId)
      expect(result).toEqual(['0', '2', '3', '4', '1', '5', '6', '7', '8', '9'])
    })

    it('when itemToMove is not in items', () => {
      const itemToMove = '10'
      const referenceId = '5'
      const result = createBeforeOrder(itemToMove, defaultModuleItems, referenceId)
      expect(result).toEqual(['0', '1', '2', '3', '4', '10', '5', '6', '7', '8', '9'])
    })
  })

  describe('createAfterOrder', () => {
    it('should return the correct order', () => {
      const itemToMove = '1'
      const referenceId = '5'
      const result = createAfterOrder(itemToMove, defaultModuleItems, referenceId)
      expect(result).toEqual(['0', '2', '3', '4', '5', '1', '6', '7', '8', '9'])
    })

    it('when itemToMove is not in items', () => {
      const itemToMove = '10'
      const referenceId = '5'
      const result = createAfterOrder(itemToMove, defaultModuleItems, referenceId)
      expect(result).toEqual(['0', '1', '2', '3', '4', '5', '10', '6', '7', '8', '9'])
    })
  })

  describe('createModuleItemOrder', () => {
    it('should return the correct order', () => {
      const moduleItemId = '5'
      const moduleItems = defaultModuleItems
      const selectedPosition = 'top'
      const selectedItem = '1'
      const result = createModuleItemOrder(
        moduleItemId,
        moduleItems,
        selectedPosition,
        selectedItem,
      )
      expect(result).toEqual(['5', '0', '1', '2', '3', '4', '6', '7', '8', '9'])
    })

    it('when moduleItemId is not in moduleItems', () => {
      const moduleItemId = '10'
      const moduleItems = defaultModuleItems
      const selectedPosition = 'top'
      const selectedItem = '1'
      const result = createModuleItemOrder(
        moduleItemId,
        moduleItems,
        selectedPosition,
        selectedItem,
      )
      expect(result).toEqual(['10', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
    })
  })

  describe('createModuleContentsOrder', () => {
    it('should return the correct order', () => {
      const sourceItems = ['5']
      const moduleItems = defaultModuleItems
      const selectedPosition = 'top'
      const selectedItem = '1'
      const result = createModuleContentsOrder(
        sourceItems,
        moduleItems,
        selectedPosition,
        selectedItem,
      )
      expect(result).toEqual(['5', '0', '1', '2', '3', '4', '6', '7', '8', '9'])
    })
  })

  describe('createModuleOrder', () => {
    it('should return the correct order', () => {
      const sourceModuleId = '5'
      const selectedPosition = 'top'
      const selectedItem = '1'
      const result = createModuleOrder(
        sourceModuleId,
        defaultModules,
        selectedPosition,
        selectedItem,
      )
      expect(result).toEqual(['5', '0', '1', '2', '3', '4'])
    })
  })

  describe('getTrayTitle', () => {
    it('should return the correct tray title for move_module_item', () => {
      const moduleAction = 'move_module_item'
      const result = getTrayTitle(moduleAction)
      expect(result).toEqual('Move Item')
    })

    it('should return the correct tray title for move_module_contents', () => {
      const moduleAction = 'move_module_contents'
      const result = getTrayTitle(moduleAction)
      expect(result).toEqual('Move Contents Into')
    })

    it('should return the correct tray title for move_module', () => {
      const moduleAction = 'move_module'
      const result = getTrayTitle(moduleAction)
      expect(result).toEqual('Move Module')
    })

    it("should return 'move' when moduleAction is not recognized", () => {
      const moduleAction = null
      const result = getTrayTitle(moduleAction)
      expect(result).toEqual('Move')
    })
  })

  describe('getErrorMessage', () => {
    it('should return the correct error message for move_module_item', () => {
      const moduleAction = 'move_module_item'
      const result = getErrorMessage(moduleAction)
      expect(result).toEqual('Error moving item')
    })

    it('should return the correct error message for move_module_contents', () => {
      const moduleAction = 'move_module_contents'
      const result = getErrorMessage(moduleAction)
      expect(result).toEqual('Error moving module contents')
    })

    it('should return the correct error message for move_module', () => {
      const moduleAction = 'move_module'
      const result = getErrorMessage(moduleAction)
      expect(result).toEqual('Error moving module')
    })

    it("should return 'error moving' when moduleAction is not recognized", () => {
      const moduleAction = null
      const result = getErrorMessage(moduleAction)
      expect(result).toEqual('Error moving')
    })
  })
})
