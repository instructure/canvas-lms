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

import {screen} from '@testing-library/dom'
import {DEFAULT_PAGE_SIZE} from '../types'
import fakeENV from '@canvas/test-utils/fakeENV'
import {
  addShowAllOrLess,
  shouldShowAllOrLess,
  itemCount,
  hasAllItemsInTheDOM,
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
  decrementModuleItemsCount,
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

type MakeModuleOptions = {
  module_id?: string
  totalItemsValue?: string | number
  loadstate?: string
}

const makeModule = (options: MakeModuleOptions = {}): HTMLElement => {
  const module_id = options.module_id || '1'
  const module = document.createElement('div')
  module.id = `context_module_${module_id}`
  module.setAttribute('data-module-id', module_id)
  const header = document.createElement('div')
  header.className = 'header'
  const admin = document.createElement('div')
  admin.className = 'ig-header-admin'
  header.appendChild(admin)
  const reqMsg = document.createElement('div')
  reqMsg.className = 'requirements_message'
  admin.appendChild(reqMsg)
  module.appendChild(header)
  const content = document.createElement('div')
  content.className = 'content'
  const contextModuleItems = document.createElement('ul')
  contextModuleItems.className = 'context_module_items'
  if (options.totalItemsValue !== undefined) {
    contextModuleItems.setAttribute('data-total-items', options.totalItemsValue.toString())
    const n = Number(options.totalItemsValue)
    if (!isNaN(n)) {
      for (let i = 0; i < n; i++) {
        const item = document.createElement('li')
        item.className = 'context_module_item'
        contextModuleItems.appendChild(item)
      }
    }
  }
  content.appendChild(contextModuleItems)
  module.appendChild(content)
  if (options.loadstate) {
    module.dataset.loadstate = options.loadstate
  }
  document.body.appendChild(module)
  return module
}

describe('showAllOrLess', () => {
  beforeEach(() => {
    fakeENV.setup({
      IS_STUDENT: false,
      FEATURE_MODULES_PERF: true,
    })
  })
  afterEach(() => {
    document.body.innerHTML = ''
    fakeENV.teardown()
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

  describe('hasAllItemsInTheDOM', () => {
    it('should return false if the module is paginated', () => {
      const module = document.createElement('div')
      module.setAttribute('data-module-id', '1')
      module.dataset.loadstate = 'paginated'
      expect(hasAllItemsInTheDOM(module)).toBe(false)
    })

    it('should return false if the module is collapsed', () => {
      const module = document.createElement('div')
      module.classList.add('collapsed_module')
      expect(hasAllItemsInTheDOM(module)).toBe(false)
    })

    it('should return true if the module is not collapsed and not paginated', () => {
      const module = document.createElement('div')
      expect(hasAllItemsInTheDOM(module)).toBe(true)
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
    it('should add the show all button to the module', () => {
      const module = makeModule({totalItemsValue: 2})
      module.dataset.loadstate = 'paginated'
      addShowAllOrLess('1')
      expect(module.querySelector('.show-all-or-less-button')).toBeInTheDocument()
      expect(module.querySelector('.show-all')).toBeInTheDocument()
      expect(screen.getByText('Show All (2)')).toBeInTheDocument()
    })

    it('should add the show less button to the module', () => {
      const module = makeModule()
      addItemsToModule(module, DEFAULT_PAGE_SIZE + 1)
      addShowAllOrLess('1')
      expect(module.querySelector('.show-all-or-less-button')).toBeInTheDocument()
      expect(module.querySelector('.show-less')).toBeInTheDocument()
      expect(screen.getByText('Show Less')).toBeInTheDocument()
    })

    it('should not add either button while the module is loading', () => {
      const module = makeModule()
      module.dataset.loadstate = 'loading'
      addShowAllOrLess('1')
      expect(module.querySelector('.show-all-or-less-button')).not.toBeInTheDocument()
    })

    it('should set the button dataset isLoading to false when method is called', () => {
      const module = makeModule()
      module.dataset.loadstate = 'paginated'
      const button = document.createElement('button')
      button.className = 'show-all-or-less-button ui-button'
      button.dataset.moduleId = '1'
      button.disabled = true
      module.appendChild(button)

      addShowAllOrLess('1')

      expect(button.dataset.isLoading).toBe('false')
      expect(button.disabled).toBe(false)
    })

    it('should set the button dataset isLoading to true when method is called', () => {
      const module = makeModule()
      module.dataset.loadstate = 'paginated'

      addShowAllOrLess('1')
      const button = module.querySelector('.show-all-or-less-button') as HTMLButtonElement
      button.click()

      expect(button.dataset.isLoading).toBe('true')
      expect(button.disabled).toBe(true)
    })

    it('should not call document dispatchEvent on isLoading true', () => {
      const spy = jest.spyOn(document, 'dispatchEvent')
      const module = makeModule()
      module.dataset.loadstate = 'paginated'

      addShowAllOrLess('1')
      const button = module.querySelector('.show-all-or-less-button') as HTMLButtonElement
      button.dataset.isLoading = 'true'
      button.click()

      expect(spy).not.toHaveBeenCalled()
      spy.mockRestore()
    })
  })

  describe('decrementModuleItemsCount', () => {
    const setupSingleModuleTest = (totalItemsValue?: string | number): HTMLElement => {
      const module = makeModule({module_id: '1', totalItemsValue, loadstate: 'paginated'})
      addShowAllOrLess('1')
      return module
    }

    const validateButtonCaption = (module: HTMLElement, expectedCount: number) => {
      const button = module.querySelector('.show-all-or-less-button') as HTMLButtonElement
      expect(button.textContent).toBe(`Show All (${expectedCount})`)
    }

    const validateTotalItemsAttribute = (module: HTMLElement, expectedValue?: string | number) => {
      const moduleContentElement = module.querySelector('.content ul') as HTMLElement
      expect(moduleContentElement.dataset.totalItems).toBe(expectedValue?.toString())
    }

    it('should decrement totalItems attribute by 1 when value is positive', () => {
      const module = setupSingleModuleTest(DEFAULT_PAGE_SIZE)
      decrementModuleItemsCount('1')
      validateTotalItemsAttribute(module, DEFAULT_PAGE_SIZE - 1)
    })

    it('should update button caption to reflect decremented count value', () => {
      const module = setupSingleModuleTest(DEFAULT_PAGE_SIZE)
      decrementModuleItemsCount('1')
      validateButtonCaption(module, DEFAULT_PAGE_SIZE - 1)
    })

    it('should not decrement when totalItems is 0', () => {
      const module = setupSingleModuleTest(0)
      decrementModuleItemsCount('1')
      validateTotalItemsAttribute(module, 0)
    })

    it('should not decrement when totalItems is negative', () => {
      const module = setupSingleModuleTest(-1)
      decrementModuleItemsCount('1')
      validateTotalItemsAttribute(module, -1)
    })

    it('should not decrement when totalItems is not a number', () => {
      const module = setupSingleModuleTest('abcd')
      decrementModuleItemsCount('1')
      validateTotalItemsAttribute(module, 'abcd')
    })

    it('should not decrement when totalItems is undefined', () => {
      const module = setupSingleModuleTest(undefined)
      decrementModuleItemsCount('1')
      validateTotalItemsAttribute(module, undefined)
    })

    describe('multiple modules', () => {
      const module1Count = 2
      const module2Count = 5
      let module1: HTMLElement
      let module2: HTMLElement

      const setupMultipleModulesTest = () => {
        module1 = makeModule({
          module_id: '1',
          totalItemsValue: module1Count,
          loadstate: 'paginated',
        })
        module2 = makeModule({
          module_id: '2',
          totalItemsValue: module2Count,
          loadstate: 'paginated',
        })
        addShowAllOrLess('1')
        addShowAllOrLess('2')
      }

      it("should only modify targeted module's totalItems attribute and leave others unchanged", () => {
        setupMultipleModulesTest()
        decrementModuleItemsCount('2')
        validateTotalItemsAttribute(module1, module1Count)
        validateTotalItemsAttribute(module2, module2Count - 1)
      })

      it("should only update the targeted module's button caption", () => {
        setupMultipleModulesTest()
        decrementModuleItemsCount('2')
        validateButtonCaption(module1, module1Count)
        validateButtonCaption(module2, module2Count - 1)
      })
    })
  })
})
