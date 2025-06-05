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

import {screen, waitFor} from '@testing-library/dom'
import fakeENV from '@canvas/test-utils/fakeENV'
import {
  updateModuleFileDrop,
  addEmptyModuleUI,
  removeEmptyModuleUI,
  type HTMLElementWithRoot,
} from '../moduleHelpers'

const buildModule = (withItems: boolean = false) => {
  const modules = document.createElement('div')
  modules.id = 'context_modules'
  document.body.appendChild(modules)

  const module = document.createElement('div')
  module.dataset.moduleId = '1'
  module.setAttribute('aria-label', 'Module 1')
  modules.appendChild(module)

  const content = document.createElement('div')
  content.className = 'content'
  module.appendChild(content)

  const ul = document.createElement('ul')
  ul.className = 'context_module_items'
  content.appendChild(ul)

  if (withItems) {
    const li = document.createElement('li')
    li.className = 'context_module_item'
    ul.appendChild(li)
  }

  const footer = document.createElement('div')
  footer.className = 'footer'
  module.appendChild(footer)

  return module
}
describe('moduleHelpers', () => {
  beforeEach(() => {
    fakeENV.setup({
      course_id: '1',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  describe('addEmptyModuleUI', () => {
    it('renders the file drop component', async () => {
      const module = buildModule()
      addEmptyModuleUI(module)
      expect(module.querySelector('.module_dnd')).toBeInTheDocument()
      await waitFor(() => {
        expect((module.querySelector('.module_dnd') as HTMLElementWithRoot).reactRoot).toBeDefined()
        expect(screen.getByTestId('module-file-drop')).toBeInTheDocument()
      })
    })
  })

  describe('removeEmptyModuleUI', () => {
    it('removes the file drop component', async () => {
      const module = buildModule()
      addEmptyModuleUI(module)
      await waitFor(() => {
        expect(screen.getByTestId('module-file-drop')).toBeInTheDocument()
      })
      removeEmptyModuleUI(module)
      expect(module.querySelector('.module_dnd')).toBeInTheDocument()
      expect((module.querySelector('.module_dnd') as HTMLElementWithRoot).reactRoot).toBeUndefined()
      await waitFor(() => {
        expect(screen.queryByTestId('module-file-drop')).not.toBeInTheDocument()
      })
    })
  })

  describe('updateModuleFileDrop', () => {
    it('renders the file drop component when the module has no items', async () => {
      const module = buildModule()
      updateModuleFileDrop(module)
      await waitFor(() => {
        expect(module.querySelector('.module_dnd')).toBeInTheDocument()
        expect((module.querySelector('.module_dnd') as HTMLElementWithRoot).reactRoot).toBeDefined()
        expect(screen.getByTestId('module-file-drop')).toBeInTheDocument()
      })
    })

    it('removes the file drop component when the module has items', async () => {
      const module = buildModule(true)
      addEmptyModuleUI(module)
      await waitFor(() => {
        expect(screen.getByTestId('module-file-drop')).toBeInTheDocument()
      })
      updateModuleFileDrop(module)
      await waitFor(() => {
        expect(screen.queryByTestId('module-file-drop')).not.toBeInTheDocument()
      })
    })
  })
})
