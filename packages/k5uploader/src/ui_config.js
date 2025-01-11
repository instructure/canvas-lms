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

function UiConfig(params) {
  this.fileFilters = []
  this.maxUploads = params.maxUploads
  this.maxFileSize = params.maxFileSize
  this.maxTotalSize = params.maxTotalSize
}

UiConfig.prototype.addFileFilter = function (fileFilter) {
  this.fileFilters.push(fileFilter)
}

UiConfig.prototype.filterFor = function (fileName) {
  let filter, f
  const extension = fileName.split('.').pop()
  for (let i = 0, len = this.fileFilters.length; i < len; i++) {
    f = this.fileFilters[i]
    if (f.includesExtension(extension)) {
      filter = f
      break
    }
  }
  return filter
}

UiConfig.prototype.asEntryParams = function (fileName) {
  const currentFilter = this.filterFor(fileName)
  return currentFilter.toParams()
}

UiConfig.prototype.acceptableFileSize = function (fileSize) {
  return this.maxFileSize * 1024 * 1024 > fileSize
}

UiConfig.prototype.acceptableFileType = function (fileName, types) {
  const currentFilter = this.filterFor(fileName)
  if (!currentFilter) {
    return false
  }
  return types.indexOf(currentFilter.id) !== -1
}

UiConfig.prototype.acceptableFile = function (file, types) {
  const type = this.acceptableFileType(file.name, types)
  const size = this.acceptableFileSize(file.size)
  return type && size
}

export default UiConfig
