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

import {Folder, File} from '../interfaces/File'

export type BackboneModel = {attributes: File}

export type MainFolderWrapperListener = (event: FilesCollectionEvent) => void

// add is triggered when used adds a file,
// remove when user removes or replaces a file and
// refetch when the user uploads an expanded zip file.
export type FilesCollectionEvent = 'add' | 'remove' | 'refetch'

export class FileFolderWrapper {
  private fileOrFolder: File | Folder

  constructor(fileOrFolder: File | Folder) {
    this.fileOrFolder = fileOrFolder
  }

  get<T>(attribute: string) {
    if (attribute === 'display_name')
      return (
        this.fileOrFolder['display_name'] ||
        this.fileOrFolder['filename'] ||
        this.fileOrFolder['name']
      )
    return this.fileOrFolder[attribute] as T
  }

  get id() {
    return this.fileOrFolder.id
  }
}

export class FileFolderCollectionWrapper extends Array<FileFolderWrapper> {
  private readonly folder: BBFolderWrapper

  constructor(folder: BBFolderWrapper) {
    super()
    this.folder = folder
  }

  // This is used in ui/shared/files/react/modules/FileOptionsCollection.jsx,
  // needed for compatibility after file upload
  add(item: BackboneModel) {
    const fileWrapper = new FileFolderWrapper(item.attributes)
    this.push(fileWrapper)
    this.folder.emit('add')
  }

  // This is used in ui/shared/files/react/modules/FileUploader.js,
  // needed for compatibility after a file replace is done
  remove(item: FileFolderWrapper) {
    const index = this.indexOf(item)
    if (index > -1) {
      this.splice(index, 1)
    }
    this.folder.emit('remove')
  }

  get(fileId: string) {
    return this.find(i => i.get('id') === fileId)
  }

  set(items: Array<FileFolderWrapper>) {
    this.clear()
    items.forEach(i => this.push(i))
  }

  clear() {
    this.length = 0
  }
  // This is used in ui/shared/files/react/modules/ZipUploader.js,
  // needed for compatibility after migration completes
  fetch() {
    this.folder.emit('refetch')
    return Promise.resolve()
  }
}

export class BBFolderWrapper {
  private readonly folder: Folder
  private readonly filesFoldersCollection: FileFolderCollectionWrapper
  private readonly listeners: Set<MainFolderWrapperListener>

  constructor(folder: Folder) {
    this.folder = folder
    this.filesFoldersCollection = new FileFolderCollectionWrapper(this)
    this.listeners = new Set()
  }

  get<T>(attribute: string) {
    return this.folder[attribute] as T
  }

  addListener(listener: MainFolderWrapperListener) {
    this.listeners.add(listener)
  }

  removeListener(listener: MainFolderWrapperListener) {
    this.listeners.delete(listener)
  }

  emit(event: FilesCollectionEvent) {
    this.listeners.forEach(listener => listener(event))
  }

  get files() {
    return this.filesFoldersCollection
  }

  get folders() {
    return this.filesFoldersCollection
  }

  get id() {
    return this.folder.id
  }
}
