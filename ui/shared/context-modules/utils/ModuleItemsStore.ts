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

// Shorten the names for memory cost reason
// p => page, s => showAll
export type ModuleData = {
  p?: string,
  s?: boolean
}

export const PREFIX = '_mperf'
export const DEFAULT_PAGE_NUMBER = '1'
export const DEFAULT_SHOW_ALL = false

export class ModuleItemsStore {
  private readonly courseId: string
  private readonly accountId: string
  private readonly userId: string

  constructor(courseId: string, accountId: string, userId: string) {
    this.courseId = courseId
    this.accountId = accountId
    this.userId = userId
  }

  private composeKey(moduleId: string) {
    return `${PREFIX}_${this.accountId}_${this.userId}_${this.courseId}_${moduleId}`
  }

  private saveToStorage(moduleId: string, moduleData: ModuleData) {
    try {
      localStorage.setItem(this.composeKey(moduleId), JSON.stringify(moduleData))
    } catch (error) {
      console.error(error)
    }
  }

  private getFromStorage(moduleId: string): ModuleData {
    const existingData = localStorage.getItem(this.composeKey(moduleId))

    try {
      return existingData ? JSON.parse(existingData) : {}
    } catch (_e) {
      return {}
    }
  }

  setPageNumber(moduleId: string, pageNumber: string) {
    const moduleData = this.getFromStorage(moduleId)
    moduleData.p = pageNumber
    this.saveToStorage(moduleId, moduleData)
  }

  getPageNumber(moduleId: string): string {
    const moduleData = this.getFromStorage(moduleId)
    return moduleData.p || DEFAULT_PAGE_NUMBER
  }

  setShowAll(moduleId: string, showAll: boolean) {
    const moduleData = this.getFromStorage(moduleId)
    moduleData.s = showAll
    this.saveToStorage(moduleId, moduleData)
  }

  getShowAll(moduleId: string): boolean {
    const moduleData = this.getFromStorage(moduleId)
    return moduleData.s || DEFAULT_SHOW_ALL
  }
}
