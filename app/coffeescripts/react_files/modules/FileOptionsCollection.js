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

import _ from 'underscore'
import UploadQueue from '../modules/UploadQueue'
import ReactDOM from 'react-dom'

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
  }

  buildDefaultState() {
    return {
      resolvedNames: [],
      nameCollisions: [],
      zipOptions: [],
      newOptions: false
    }
  }

  queueUploads(contextId, contextType) {
    this.state.resolvedNames.forEach(f => {
      UploadQueue.enqueue(f, this.folder, contextId, contextType)
    })
    this.setState({newOptions: false})
  }

  toFilesOptionArray(fList) {
    return [].slice.call(fList, 0).map(file => ({file}))
  }

  findMatchingFile(name) {
    return _.find(this.folder.files.models, f => f.get('display_name') === name)
  }

  isZipFile(file) {
    return !!(file.type != null ? file.type.match(/zip/) : undefined)
  }

  // divide into existing naming collisions and resolved ones
  segregateOptionBuckets(selectedFiles) {
    const [collisions, resolved, zips] = [[], [], []]
    selectedFiles.forEach(file => {
      if (this.isZipFile(file.file) && typeof file.expandZip === 'undefined') {
        zips.push(file)
        // only mark as collision if it is a collision that hasn't been resolved, or is is a zip that will be expanded
      } else {
        const nameToTest = file.name || file.file.name
        const matchingFile = this.findMatchingFile(nameToTest)
        if (
          matchingFile &&
          (file.dup !== 'overwrite' && (file.expandZip == null || file.expandZip === false))
        ) {
          if (matchingFile.get('restricted_by_master_course')) {
            file.cannotOverwrite = true
          }
          collisions.push(file)
        } else {
          resolved.push(file)
        }
      }
    })

    return {collisions, resolved, zips}
  }

  handleAddFilesClick() {
    return ReactDOM.findDOMNode(this.refs.addFileInput).click()
  }

  handleFilesInputChange(e) {
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
      newOptions: true
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
    return (this.state = _.defaults(options, this.state))
  }

  getState() {
    return this.state
  }

  resetState() {
    return (this.state = this.buildDefaultState())
  }

  // noop
  onChange() {}
}

export default new FileOptionsCollection()
