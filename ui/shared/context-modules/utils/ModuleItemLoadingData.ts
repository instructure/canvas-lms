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

import {createRoot, type Root} from 'react-dom/client'
import {type ModuleId, type PaginationData} from './types'

type ModuleData = {
  moduleId: ModuleId
  paginationData?: PaginationData
  root?: Root
}

class ModuleItemLoadingData {
  private modules: Record<ModuleId, ModuleData> = {}

  private getModuleData(moduleId: ModuleId): ModuleData {
    if (!this.modules[moduleId]) {
      this.addModule(moduleId)
    }
    return this.modules[moduleId]
  }

  private addModule(moduleId: ModuleId): ModuleData {
    this.modules[moduleId] = {
      moduleId,
    }
    return this.modules[moduleId]
  }

  getPaginationData(moduleId: ModuleId): PaginationData | undefined {
    const moduleData = this.getModuleData(moduleId)
    return moduleData.paginationData ? {...moduleData.paginationData} : undefined
  }

  setPaginationData(moduleId: ModuleId, paginationData: PaginationData): void {
    const moduleData = this.getModuleData(moduleId)
    moduleData.paginationData = {...paginationData}
  }

  removePaginationData(moduleId: ModuleId): void {
    const moduleData = this.getModuleData(moduleId)
    delete moduleData.paginationData
  }

  getModuleRoot(moduleId: ModuleId): Root | undefined {
    const moduleData = this.getModuleData(moduleId)
    if (moduleData.root) {
      return moduleData.root
    }

    const moduleItemContainer = document.querySelector(`#context_module_content_${moduleId}`)
    if (!moduleItemContainer) {
      return undefined
    }

    let pagingDiv = moduleItemContainer.querySelector(`.item-paging`)
    if (!pagingDiv) {
      pagingDiv = document.createElement('div')
      pagingDiv.id = `context_module_${moduleId}_paging`
      pagingDiv.className = 'item-paging'
      moduleItemContainer.insertAdjacentElement('beforeend', pagingDiv)
    }
    moduleData.root = createRoot(pagingDiv)
    return moduleData.root
  }

  unmountModuleRoot(moduleId: ModuleId): void {
    const moduleData = this.getModuleData(moduleId)
    if (moduleData.root) {
      moduleData.root.unmount()
      moduleData.root = undefined
    }
  }
}

export {ModuleItemLoadingData, type ModuleData}
