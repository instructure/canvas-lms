/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import React from 'react'
import {string} from 'prop-types'
import I18n from 'i18n!context_modulesFileSelectBox'
import FileStore from './stores/FileStore'
import FolderStore from './stores/FolderStore'
import natcompare from 'compiled/util/natcompare'
import splitAssetString from 'compiled/str/splitAssetString'

export default class FileSelectBox extends React.Component {
  static propTypes = {
    contextString: string.isRequired
  }

  state = {
    folders: []
  }

  isDirty = true

  componentWillMount() {
    this.refresh()
  }

  setDirty() {
    this.isDirty = true
  }

  refresh() {
    if (this.isDirty) {
      // Get a decent url partial in order to create the store.
      const contextUrl = splitAssetString(this.props.contextString).join('/')

      // Create the stores, and add change listeners to them.
      this.fileStore = new FileStore(contextUrl, {perPage: 50, only: ['names']})
      this.folderStore = new FolderStore(contextUrl, {perPage: 50})
      this.fileStore.addChangeListener(() => {
        this.setState({
          files: this.fileStore.getState().items
        })
      })
      this.folderStore.addChangeListener(() => {
        this.setState({
          folders: this.folderStore.getState().items
        })
      })

      // Fetch the data.
      this.fileStore.fetch({fetchAll: true})
      this.folderStore.fetch({fetchAll: true})
      this.isDirty = false
    }
  }

  getFolderById = id => {
    return this.state.folders.find(folder => folder.id.toString() === id)
  }

  // Let's us know if the stores are still loading data.
  isLoading = () => this.fileStore.getState().isLoading || this.folderStore.getState().isLoading

  createFolderFileTreeStructure = () => {
    let {folders, files} = this.state

    // Put files into the right folders.
    const groupedFiles = _.groupBy(files, 'folder_id')
    for (const key in groupedFiles) {
      const folder = _.findWhere(folders, {id: parseInt(key, 10)})
      if (folder) {
        folder.files = groupedFiles[key]
      }
    }

    folders = folders.sort((a, b) =>
      // Make sure we use a sane sorting mechanism.
      natcompare.strings(a.full_name, b.full_name)
    )

    return folders
  }

  renderFilesAndFolders = () => {
    const tree = this.createFolderFileTreeStructure()

    if (this.isLoading()) {
      return <option>{I18n.t('Loading...')}</option>
    }

    const renderFiles = function(folder) {
      return folder.files.map(file => (
        <option key={`file-${file.id}`} value={file.id}>
          {file.display_name}
        </option>
      ))
    }

    return tree.map(folder => {
      if (folder.files) {
        return (
          <optgroup key={`folder-${folder.id}`} label={folder.full_name}>
            {renderFiles(folder)}
          </optgroup>
        )
      }
    })
  }

  render() {
    const moduleDnd = window?.ENV?.FEATURES?.module_dnd
    const newQuizzesModulesSupport = window?.ENV?.new_quizzes_modules_support
    const ariaLabel = newQuizzesModulesSupport
      ? moduleDnd
        ? I18n.t(
            'Select the files you want to associate, or add files by selecting "Create File(s)".'
          )
        : I18n.t('Select the file you want to associate, or add a file by selecting "Create File".')
      : moduleDnd
      ? I18n.t('Select the files you want to associate, or add files by selecting "New File(s)".')
      : I18n.t('Select the file you want to associate, or add a file by selecting "New File".')
    const newFile = newQuizzesModulesSupport
      ? moduleDnd
        ? I18n.t('[ Create File(s) ]')
        : I18n.t('[ Create File ]')
      : moduleDnd
      ? I18n.t('[ New File(s) ]')
      : I18n.t('[ New File ]')
    return (
      <div>
        <select
          ref="selectBox"
          aria-busy={this.isLoading()}
          className="module_item_select"
          aria-label={ariaLabel}
          multiple
        >
          <option value="new">{newFile}</option>
          {this.renderFilesAndFolders()}
        </select>
      </div>
    )
  }
}
