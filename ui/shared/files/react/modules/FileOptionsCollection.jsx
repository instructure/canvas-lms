/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {defaults} from 'lodash'
import UploadQueue from './UploadQueue'
import ReactDOM from 'react-dom'
import * as CategoryProcessor from '@instructure/canvas-rce/es/rce/plugins/shared/Upload/CategoryProcessor'

/*
Manages buckets of FileOptions (resolved, nameCollisions, zipOptions)

FileOption:
  file: <File>
  dup: how to handle duplicate names rename || overwrite (used in api call)
  name: name by which to upload the file
  expandZip: (bool) upload the zip or expand it to current directory
*/
class FileOptionsCollection {
  constructor() {
    this.state = this.buildDefaultState()

    this.uploadOptions = {
      alwaysRename: false,
      alwaysUploadZips: false,
    }
  }

  buildDefaultState() {
    return {
      resolvedNames: [],
      nameCollisions: [],
      zipOptions: [],
      newOptions: false,
    }
  }

  async applyCategory(fileOptions) {
    const getCategory = async option => {
      const category = await CategoryProcessor.process(option.file)

      return {
        ...option,
        ...category,
      }
    }

    return Promise.all(fileOptions.map(getCategory))
  }

  queueUploads(contextId, contextType) {
    // Some uploaded files require a certain category be applied to them.
    // We use "applyCategory" and CategoryProcessor to add those categories
    // according to file type and content.
    this.applyCategory(this.state.resolvedNames)
      .then(resolvedNamesWithCategories => {
        resolvedNamesWithCategories.forEach(f => {
          UploadQueue.enqueue(f, this.folder, contextId, contextType)
        })
      })
      .catch(error => {
        throw error
      })

    this.setState({newOptions: false})
  }

  toFilesOptionArray(fList) {
    return [].slice.call(fList, 0).map(file => ({file}))
  }

  findMatchingFile(name) {
    return (this.folder.files.models || this.folder.files).find(f => f.get('display_name') === name)
  }

  isZipFile(file) {
    return !!(file.type != null ? file.type.match(/zip/) : undefined)
  }

  // divide into existing naming collisions and resolved ones
  segregateOptionBuckets(selectedFiles) {
    const [collisions, resolved, zips] = [[], [], []]
    selectedFiles.forEach(file => {
      if (this.isZipFile(file.file) && this.uploadOptions.alwaysUploadZips) {
        file.expandZip = false // treat this as a plain old file
      }
      if (this.isZipFile(file.file) && typeof file.expandZip === 'undefined') {
        zips.push(file)
        // only mark as collision if it is a collision that hasn't been resolved, or is is a zip that will be expanded
      } else if (file.dup !== 'skip') {
        const nameToTest = file.name || file.file.name
        const matchingFile = this.findMatchingFile(nameToTest)
        if (
          matchingFile &&
          file.dup !== 'overwrite' &&
          (file.expandZip == null || file.expandZip === false) &&
          !this.uploadOptions.alwaysRename
        ) {
          if (matchingFile.get('restricted_by_master_course')) {
            file.cannotOverwrite = true
          }
          collisions.push(file)
        } else {
          file.replacingFileId = matchingFile?.id
          resolved.push(file)
        }
      }
    })
    return {collisions, resolved, zips}
  }

  handleAddFilesClick() {
    return ReactDOM.findDOMNode(this.refs.addFileInput).click()
  }

  handleFilesInputChange(_e) {
    const selectedFiles = this.toFilesOptionArray(
      ReactDOM.findDOMNode(this.refs.addFileInput).files
    )
    const {resolved, collisions, zips} = this.segregateOptionBuckets(selectedFiles)
    this.setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips})
  }

  onNameConflictResolved(fileNameOptions) {
    let collisions, resolved
    const {nameCollisions} = this.state
    const {resolvedNames} = this.state
    let zips = this.state.zipOptions

    resolvedNames.push(fileNameOptions)
    // TODO: only difference is that we remove the first nameCollision here
    nameCollisions.shift()

    // redo conflict resolution, new name from user could still conflict
    const allOptions = resolvedNames.concat(nameCollisions).concat(zips)
    // eslint-disable-next-line prefer-const
    ;({resolved, collisions, zips} = this.segregateOptionBuckets(allOptions))
    this.setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips})
  }

  onZipOptionsResolved(fileNameOptions) {
    let collisions, resolved
    const {nameCollisions} = this.state
    const {resolvedNames} = this.state
    let zips = this.state.zipOptions

    resolvedNames.push(fileNameOptions)
    // TODO: only difference is that we remove the first zip here
    zips.shift()

    // redo conflict resolution, new name from user could still conflict
    const allOptions = resolvedNames.concat(nameCollisions).concat(zips)
    // eslint-disable-next-line prefer-const
    ;({resolved, collisions, zips} = this.segregateOptionBuckets(allOptions))
    this.setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips})
  }

  setOptionsFromFiles(files, notifyChange) {
    const allOptions = this.toFilesOptionArray(files)
    const {resolved, collisions, zips} = this.segregateOptionBuckets(allOptions)
    this.setState({
      nameCollisions: collisions,
      resolvedNames: resolved,
      zipOptions: zips,
      newOptions: true,
    })
    if (notifyChange && this.onChange) {
      return this.onChange()
    }
  }

  hasNewOptions() {
    return this.state.newOptions
  }

  setFolder(folder) {
    return (this.folder = folder)
  }

  getFolder() {
    return this.folder
  }

  setState(options) {
    return (this.state = defaults(options, this.state))
  }

  getState() {
    return this.state
  }

  resetState() {
    return (this.state = this.buildDefaultState())
  }

  setUploadOptions(options) {
    this.uploadOptions.alwaysRename = !!options.alwaysRename
    this.uploadOptions.alwaysUploadZips = !!options.alwaysUploadZips
  }

  // noop
  onChange() {}
}

export default new FileOptionsCollection()
