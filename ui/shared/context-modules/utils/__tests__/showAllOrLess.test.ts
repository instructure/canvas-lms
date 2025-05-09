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

import {DEFAULT_PAGE_SIZE} from '../ModuleItemsLazyLoader'
import {
  addShowAllOrLess,
  shouldShowAllOrLess,
  itemCount,
  isModuleCurrentPageEmpty,
  isModuleCollapsed,
  isModulePaginated,
  isModuleLoading,
  expandModuleAndLoadAll,
  loadAll,
  loadFirstPage,
  maybeExpandAndLoadAll,
  MODULE_EXPAND_AND_LOAD_ALL,
  MODULE_LOAD_ALL,
  MODULE_LOAD_FIRST_PAGE,
} from '../showAllOrLess'

declare const ENV: {
  IS_STUDENT?: boolean
}

const addItemsToModule = (module: HTMLElement, count: number) => {
  for (let i = 0; i < count; i++) {
    const item = document.createElement('div')
    item.classList.add('context_module_item')
    module.appendChild(item)
  }
}

describe('showAllOrLess', () => {
  beforeEach(() => {
    ENV.IS_STUDENT = false
  })
  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('isModuleCurrentPageEmpty', () => {
    it('should return true if the module is empty', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      expect(isModuleCurrentPageEmpty(module)).toBe(true)
    })

    it('should return false if the module is not empty', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      addItemsToModule(module, 1)
      expect(isModuleCurrentPageEmpty(module)).toBe(false)
    })
  })

  describe('isModuleLoading', () => {
    it('should return true if the module is loading', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      module.dataset.loadstate = 'loading'
      expect(isModuleLoading(module)).toBe(true)
    })

    it('should return false if the module is not loading', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      expect(isModuleLoading(module)).toBe(false)
    })
  })

  describe('isModulePaginated', () => {
    it('should return true if the module is paginated', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      module.dataset.loadstate = 'paginated'
      expect(isModulePaginated(module)).toBe(true)
    })

    it('should return false if the module is not paginated', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      expect(isModulePaginated(module)).toBe(false)
    })
  })

  describe('isModuleCollapsed', () => {
    it('should return true if the module is collapsed', () => {
      const module = document.createElement('div')
      module.classList.add('collapsed_module')
      expect(isModuleCollapsed(module)).toBe(true)
    })

    it('should return false if the module is not collapsed', () => {
      const module = document.createElement('div')
      expect(isModuleCollapsed(module)).toBe(false)
    })
  })

  describe('itemCount', () => {
    it('should return the number of items in the module', () => {
      const module = document.createElement('div')
      addItemsToModule(module, 5)
      expect(itemCount(module)).toBe(5)
    })
  })

  describe('shouldShowAllOrLess', () => {
    it('should return "none" if the module is collapsed', () => {
      const module = document.createElement('div')
      module.classList.add('collapsed_module')
      expect(shouldShowAllOrLess(module)).toBe('none')
    })

    it('should return "all" if the module is paginated', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      module.dataset.loadstate = 'paginated'
      expect(shouldShowAllOrLess(module)).toBe('all')
    })

    it('should return "less" if the module has more than DEFAULT_PAGE_SIZE items', () => {
      const module = document.createElement('div')
      addItemsToModule(module, DEFAULT_PAGE_SIZE + 1)
      expect(shouldShowAllOrLess(module)).toBe('less')
    })

    it('should return "none" if the module has less than DEFAULT_PAGE_SIZE items', () => {
      const module = document.createElement('div')
      addItemsToModule(module, DEFAULT_PAGE_SIZE - 1)
      expect(shouldShowAllOrLess(module)).toBe('none')
    })

    it('should return "none" if the module has DEFAULT_PAGE_SIZE items', () => {
      const module = document.createElement('div')
      addItemsToModule(module, DEFAULT_PAGE_SIZE)
      expect(shouldShowAllOrLess(module)).toBe('none')
    })
  })

  describe('expandModuleAndLoadAll', () => {
    it('should fire the event', (done: jest.DoneCallback) => {
      document.addEventListener(MODULE_EXPAND_AND_LOAD_ALL, ((event: Event) => {
        const customEvent = event as CustomEvent<{moduleId: string; allPages: boolean}>
        expect(customEvent.detail.moduleId).toBe('1')
        expect(customEvent.detail.allPages).toBe(true)
        done()
      }) as EventListener)
      expandModuleAndLoadAll('1')
    })
  })

  describe('loadAll', () => {
    it('should fire the event', (done: jest.DoneCallback) => {
      document.addEventListener(MODULE_LOAD_ALL, ((event: Event) => {
        const customEvent = event as CustomEvent<{moduleId: string}>
        expect(customEvent.detail.moduleId).toBe('1')
        done()
      }) as EventListener)
      loadAll('1')
    })
  })

  describe('loadFirstPage', () => {
    it('should fire the event', (done: jest.DoneCallback) => {
      document.addEventListener(MODULE_LOAD_FIRST_PAGE, ((event: Event) => {
        const customEvent = event as CustomEvent<{moduleId: string}>
        expect(customEvent.detail.moduleId).toBe('1')
        done()
      }) as EventListener)
      loadFirstPage('1')
    })
  })

  describe('maybeExpandAndLoadAll', () => {
    it('should call expandModuleAndLoadAll when module is collapsed', (done: jest.DoneCallback) => {
      const module = document.createElement('div')
      module.id = 'context_module_1'
      module.setAttribute('data-module-id', '1')
      module.classList.add('collapsed_module')
      document.body.appendChild(module)
      document.addEventListener(MODULE_EXPAND_AND_LOAD_ALL, ((event: Event) => {
        const customEvent = event as CustomEvent<{moduleId: string; allPages: boolean}>
        expect(customEvent.detail.moduleId).toBe('1')
        expect(customEvent.detail.allPages).toBe(true)
        done()
      }) as EventListener)
      maybeExpandAndLoadAll('1')
    })

    it('should call loadAll when module is paginated', (done: jest.DoneCallback) => {
      const module = document.createElement('div')
      module.id = 'context_module_1'
      module.setAttribute('data-module-id', '1')
      module.dataset.loadstate = 'paginated'
      document.body.appendChild(module)
      document.addEventListener(MODULE_LOAD_ALL, ((event: Event) => {
        const customEvent = event as CustomEvent<{moduleId: string}>
        expect(customEvent.detail.moduleId).toBe('1')
        done()
      }) as EventListener)
      maybeExpandAndLoadAll('1')
    })
  })

  describe('addShowAllOrLess', () => {
    const makeModule = (): HTMLElement => {
      const module = document.createElement('div')
      module.id = 'context_module_1'
      module.setAttribute('data-module-id', '1')
      const header = document.createElement('div')
      header.className = 'header'
      const admin = document.createElement('div')
      admin.className = 'ig-header-admin'
      header.appendChild(admin)
      const reqMsg = document.createElement('div')
      reqMsg.className = 'requirements_message'
      admin.appendChild(reqMsg)
      module.appendChild(header)
      document.body.appendChild(module)
      return module
    }

    it('should add the show all button to the module', () => {
      const module = makeModule()
      module.dataset.loadstate = 'paginated'
      addShowAllOrLess('1')
      expect(module.querySelector('.show-all-or-less-button')).toBeInTheDocument()
      expect(module.querySelector('.show-all')).toBeInTheDocument()
    })

    it('should add the show less button to the module', () => {
      const module = makeModule()
      addItemsToModule(module, DEFAULT_PAGE_SIZE + 1)
      addShowAllOrLess('1')
      expect(module.querySelector('.show-all-or-less-button')).toBeInTheDocument()
      expect(module.querySelector('.show-less')).toBeInTheDocument()
    })

    it('should not add either button while the module is loading', () => {
      const module = makeModule()
      module.dataset.loadstate = 'loading'
      addShowAllOrLess('1')
      expect(module.querySelector('.show-all-or-less-button')).not.toBeInTheDocument()
    })
  })
})
