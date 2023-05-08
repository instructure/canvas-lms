// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

interface backboneSpan extends HTMLSpanElement {
  model?: any
  data?: any
}

function makeModel(type, id, module_item_id) {
  return {
    attributes: {
      type,
      id,
      module_item_id,
    },
    view: {
      render: jest.fn(),
    },
  }
}

export function makeModuleItem(courseId, moduleId, {content_type, content_id}) {
  const module_item_id = 1000 * moduleId + content_id

  const item = document.createElement('div')
  item.id = `context_module_item_${module_item_id}`
  const row = document.createElement('div')
  row.className = 'ig-row'
  item.appendChild(row)
  const admin = document.createElement('div')
  admin.className = 'ig-admin'
  item.appendChild(admin)

  const publishButton: backboneSpan = document.createElement('span')
  publishButton.setAttribute('data-course-id', courseId)
  publishButton.setAttribute('data-module-id', moduleId)
  publishButton.setAttribute('data-module-item-id', `${module_item_id}`)
  publishButton.className = 'publish-icon'
  const $publishButton = $(publishButton) // sets up jquery's data()

  $publishButton.data({
    moduleId,
    view: {
      model: makeModel(content_type, content_id, module_item_id),
    },
  })

  admin.appendChild(publishButton)
  return item
}

export function makeModule(
  moduleId: number,
  moduleName: string,
  published: boolean = false
): HTMLDivElement {
  const module = document.createElement('div')
  module.id = `context_module_${moduleId}`
  module.className = 'context_module'
  module.setAttribute('data-module-id', `${moduleId}`)
  const moduleTitle = document.createElement('div')
  moduleTitle.className = 'ig-header-title'
  moduleTitle.textContent = 'Lesson 2'
  module.appendChild(moduleTitle)
  const publishModuleButton = document.createElement('div')
  publishModuleButton.className = 'module-publish-icon'
  publishModuleButton.setAttribute('data-course-id', '1')
  publishModuleButton.setAttribute('data-module-id', moduleId.toString())
  const $publishModuleButton = $(publishModuleButton)
  $publishModuleButton.data('moduleId', moduleId)
  $publishModuleButton.data('published', published)
  module.appendChild(publishModuleButton)
  const content = document.createElement('div')
  content.id = `context_module_content_${moduleId}`
  module.appendChild(content)
  document.getElementById('context_modules')?.appendChild(module)
  return module
}

export function makeModuleWithItems(
  moduleId: number,
  moduleName: string,
  itemIds: number[],
  published: boolean = false
): void {
  makeModule(moduleId, moduleName, published)
  const moduleContent = document.getElementById(`context_module_content_${moduleId}`)
  itemIds.forEach(id => {
    moduleContent?.appendChild(
      makeModuleItem(1, moduleId, {content_type: 'assignment', content_id: id})
    )
  })
}

export function initBody() {
  document.body.innerHTML = '<div id="context_modules"></div>'
}
