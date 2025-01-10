/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

interface FileFilter {
  id: string
  includesExtension(extension: string): boolean
  toParams(): {[key: string]: string}
}

interface UiConfigParams {
  maxUploads: number
  maxFileSize: number
  maxTotalSize: number
}

class UiConfig {
  fileFilters: FileFilter[]
  maxUploads: number
  maxFileSize: number
  maxTotalSize: number

  constructor(params: UiConfigParams) {
    this.fileFilters = []
    this.maxUploads = params.maxUploads
    this.maxFileSize = params.maxFileSize
    this.maxTotalSize = params.maxTotalSize
  }

  addFileFilter(fileFilter: FileFilter): void {
    this.fileFilters.push(fileFilter)
  }

  filterFor(fileName: string): FileFilter | undefined {
    const extension = fileName.split('.').pop()
    for (let i = 0, len = this.fileFilters.length; i < len; i++) {
      const f = this.fileFilters[i]
      if (f.includesExtension(extension || '')) {
        return f
      }
    }
    return undefined
  }

  asEntryParams(fileName: string): {[key: string]: string} | undefined {
    const currentFilter = this.filterFor(fileName)
    return currentFilter ? currentFilter.toParams() : undefined
  }

  acceptableFileSize(fileSize: number): boolean {
    return this.maxFileSize * 1024 * 1024 > fileSize
  }

  acceptableFileType(fileName: string, types: string[]): boolean {
    const currentFilter = this.filterFor(fileName)
    if (!currentFilter) {
      return false
    }
    return types.indexOf(currentFilter.id) !== -1
  }

  acceptableFile(file: {name: string; size: number}, types: string[]): boolean {
    const type = this.acceptableFileType(file.name, types)
    const size = this.acceptableFileSize(file.size)
    return type && size
  }
}

export default UiConfig
