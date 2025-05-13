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

import {ModuleItemLoadingData} from '../ModuleItemLoadingData'

describe('ModuleItemLoadingData', () => {
  const moduleId = '17'

  let modules: ModuleItemLoadingData

  beforeEach(() => {
    modules = new ModuleItemLoadingData()
    document.body.innerHTML = ''
  })

  describe('PaginationData', () => {
    it('set sets the pagination data for a module', () => {
      modules.setPaginationData(moduleId, {currentPage: 2, totalPages: 3})
      const paginationData = modules.getPaginationData(moduleId)
      expect(paginationData).toEqual({currentPage: 2, totalPages: 3})
    })

    it('treats pagination data as immutable', () => {
      modules.setPaginationData(moduleId, {currentPage: 1, totalPages: 1})
      const paginationData = modules.getPaginationData(moduleId)!
      paginationData.currentPage = 2
      paginationData.totalPages = 3
      const paginationData2 = modules.getPaginationData(moduleId)
      expect(paginationData2).toEqual({currentPage: 1, totalPages: 1})
    })
  })

  describe('getModuleRoot', () => {
    it('should return undefined if the item container does not exist', () => {
      const root = modules.getModuleRoot(moduleId)
      expect(root).toBeUndefined()
    })

    it('should return the root for a module', () => {
      const moduleItemContainer = document.createElement('div')
      moduleItemContainer.id = `context_module_content_${moduleId}`
      document.body.appendChild(moduleItemContainer)

      const root = modules.getModuleRoot(moduleId)
      expect(root).toBeDefined()
      expect(root).toHaveProperty('render')
    })

    it('should always return the same root when asked', () => {
      const moduleItemContainer = document.createElement('div')
      moduleItemContainer.id = `context_module_content_${moduleId}`
      document.body.appendChild(moduleItemContainer)

      const root = modules.getModuleRoot(moduleId)
      expect(root).toBeDefined()

      const root2 = modules.getModuleRoot(moduleId)
      expect(root2).toBe(root)
    })
  })

  describe('unmountModuleRoot', () => {
    it('should unmount the root for a module', () => {
      const moduleItemContainer = document.createElement('div')
      moduleItemContainer.id = `context_module_content_${moduleId}`
      document.body.appendChild(moduleItemContainer)

      const root = modules.getModuleRoot(moduleId)
      expect(root).toBeDefined()
      expect(root).toHaveProperty('render')

      // @ts-expect-error
      const spy = jest.spyOn(root, 'unmount')

      modules.unmountModuleRoot(moduleId)
      expect(spy).toHaveBeenCalled()
    })

    it('should not fail if the root does not exist', () => {
      expect(() => modules.unmountModuleRoot(moduleId)).not.toThrow()
    })
  })
})
