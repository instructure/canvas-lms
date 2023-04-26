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

function makeModel(type, id) {
  return {
    attributes: {
      type,
      id,
    },
    view: {
      render: jest.fn(),
    },
  }
}

export function makeModuleItem(courseId, moduleId, {item_type, item_id}) {
  const item = document.createElement('div')
  item.id = `context_module_item-${item_id}`
  const admin = document.createElement('div')
  admin.className = 'ig-admin'
  item.appendChild(admin)

  const publishButton: backboneSpan = document.createElement('span')
  publishButton.setAttribute('data-course-id', courseId)
  publishButton.setAttribute('data-module-id', moduleId)
  publishButton.setAttribute('data-module-item-id', item_id)
  publishButton.className = 'publish-icon'
  const $publishButton = $(publishButton) // sets up jquery's data()

  $publishButton.data({
    moduleId,
    view: {
      model: makeModel(item_type, item_id),
    },
  })

  publishButton.model = makeModel(item_type, item_id)
  publishButton.data = {
    view: {
      model: publishButton.model,
    },
  }

  admin.appendChild(publishButton)
  return item
}

export function makeModule(moduleId: number, published: boolean = false): HTMLDivElement {
  const module = document.createElement('div')
  module.id = `context_module_${moduleId}`
  module.className = 'context_module'
  module.setAttribute('data-module-id', `${moduleId}`)
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
  document.body.appendChild(module)
  return module
}

export function makeModuleWithItems(moduleId, published = false) {
  makeModule(moduleId, published)
  const moduleContent = document.getElementById(`context_module_content_${moduleId}`)
  moduleContent?.appendChild(
    makeModuleItem(1, moduleId, {item_type: 'assignment', item_id: `${moduleId * 100 + 17}`})
  )
  moduleContent?.appendChild(
    makeModuleItem(1, moduleId, {item_type: 'assignment', item_id: `${moduleId * 100 + 19}`})
  )
}
