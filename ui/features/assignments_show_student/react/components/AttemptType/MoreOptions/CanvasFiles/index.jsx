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

import {arrayOf, func, shape, string} from 'prop-types'
import axios from '@canvas/axios'
import BreadcrumbLinkWithTip from './BreadcrumbLinkWithTip'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import FileSelectTable from './FileSelectTable'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import React from 'react'

import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('assignments_2_MoreOptions_CanvasFiles')

class CanvasFiles extends React.Component {
  state = {
    loadedFolders: {0: {id: '0', name: I18n.t('Root'), subFileIDs: [], subFolderIDs: []}},
    loadedFiles: {},
    error: null,
    pendingAPIRequests: 0,
    selectedFolderID: '0',
  }

  FILE_TYPE = 'files'

  FOLDER_TYPE = 'folders'

  ROOT_FOLDER_ID = '0'

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
    this.loadUserRootFolders()
  }

  componentWillUnmount() {
    this._isMounted = false
  }

  folderContentApiUrl = (folderID, type) => {
    return `/api/v1/folders/${folderID}/${type}?include=user`
  }

  folderContentsLoaded = (folderID, type) => {
    const folder = this.state.loadedFolders[folderID]
    return type === this.FILE_TYPE
      ? folder && folder.subFileIDs && folder.subFileIDs.length
      : folder && folder.subFolderIDs && folder.subFolderIDs.length
  }

  handleUpdateSelectedFolder = folderID => {
    if (folderID !== this.ROOT_FOLDER_ID) {
      if (!this.folderContentsLoaded(folderID, this.FILE_TYPE)) {
        this.loadFolderContents(folderID, this.FILE_TYPE)
      }
      if (!this.folderContentsLoaded(folderID, this.FOLDER_TYPE)) {
        this.loadFolderContents(folderID, this.FOLDER_TYPE)
      }
    }
    if (this._isMounted) {
      this.setState({selectedFolderID: folderID}, () => {
        // we are guaranteed to always have a folder in the selection, so we will either focus
        // on the parent folder, or the first rendered folder in the root
        const newFocus =
          document.getElementById('parent-folder') ||
          document.getElementById(
            `folder-${this.state.loadedFolders[this.state.selectedFolderID].subFolderIDs[0]}`
          )
        newFocus.focus()
      })
    }
  }

  loadUserRootFolders = () => {
    if (!this.folderContentsLoaded(this.ROOT_FOLDER_ID, this.FOLDER_TYPE)) {
      const opts = {Accepts: 'application/json+canvas-string-ids'}
      // load user folders
      this.loadFolderContents(
        this.ROOT_FOLDER_ID,
        this.FOLDER_TYPE,
        '/api/v1/users/self/folders/root',
        opts
      )

      // load group folders
      this.props.userGroups.forEach(group => {
        this.loadFolderContents(
          this.ROOT_FOLDER_ID,
          this.FOLDER_TYPE,
          `/api/v1/groups/${group._id}/folders/root`,
          {...opts, group_name: group.name}
        )
      })
    }
  }

  loadFolderContents = async (folderID, type, url, opts = {}) => {
    try {
      if (this._isMounted) {
        this.setState(prevState => ({pendingAPIRequests: prevState.pendingAPIRequests + 1}))
      }
      const requestUrl = url || this.folderContentApiUrl(folderID, type)
      const resp = await axios.get(requestUrl, opts)
      const newItems = Array.isArray(resp.data) ? resp.data : [resp.data]
      if (opts.group_name) {
        newItems.forEach(item => (item.name = opts.group_name))
      }
      this.updateLoadedItems(type, newItems)

      const nextUrl = parseLinkHeader(resp.headers.link).next
      if (nextUrl) {
        this.loadFolderContents(folderID, type, nextUrl, opts)
      }
    } catch (err) {
      if (this._isMounted) {
        this.setState({error: err})
      }
    } finally {
      if (this._isMounted) {
        this.setState(prevState => ({pendingAPIRequests: prevState.pendingAPIRequests - 1}))
      }
    }
  }

  updateLoadedItems = (type, newItems) => {
    if (type === this.FILE_TYPE) {
      this.updateLoadedFiles(newItems)
    } else {
      this.updateLoadedFolders(newItems)
    }
  }

  formatFolderData = folder => {
    return {
      ...folder,
      subFolderIDs: [],
      subFileIDs: [],
    }
  }

  updateLoadedFolders = newFolders => {
    if (this._isMounted) {
      this.setState(prevState => {
        const loadedFolders = JSON.parse(JSON.stringify(prevState.loadedFolders))
        newFolders.forEach(folder => {
          folder = this.formatFolderData(folder)
          folder.parent_folder_id = folder.parent_folder_id || 0

          const parent = loadedFolders.hasOwnProperty(folder.parent_folder_id)
            ? loadedFolders[folder.parent_folder_id]
            : {subFileIDs: [], subFolderIDs: []}
          if (!parent.subFolderIDs.includes(folder.id)) {
            parent.subFolderIDs.push(folder.id)
            loadedFolders[folder.parent_folder_id] = {
              ...loadedFolders[folder.parent_folder_id],
              ...parent,
            }
          }

          if (loadedFolders[folder.id]) {
            folder.subFolderIDs = loadedFolders[folder.id].subFolderIDs
          }
          loadedFolders[folder.id] = folder
        })
        return {loadedFolders}
      })
    }
  }

  updateLoadedFiles = newFiles => {
    if (this._isMounted) {
      this.setState(prevState => {
        const loadedFolders = JSON.parse(JSON.stringify(prevState.loadedFolders))
        const loadedFiles = JSON.parse(JSON.stringify(prevState.loadedFiles))
        newFiles.forEach(file => {
          const parentID = file.folder_id || 0

          const parent = loadedFolders.hasOwnProperty(parentID)
            ? loadedFolders[parentID]
            : {subFileIDs: [], subFolderIDs: []}
          if (!parent.subFileIDs.includes(file.id)) {
            parent.subFileIDs.push(file.id)
            loadedFolders[parentID] = {...loadedFolders[parentID], ...parent}
          }

          loadedFiles[file.id] = file
        })
        return {loadedFolders, loadedFiles}
      })
    }
  }

  renderFolderPathBreadcrumb = () => {
    const path = []
    let folder = this.state.loadedFolders[this.state.selectedFolderID]
    while (folder) {
      path.unshift({id: folder.id, name: folder.name})
      folder = this.state.loadedFolders[folder.parent_folder_id]
    }

    return (
      <Flex.Item padding="medium xx-small xx-small xx-small">
        <Breadcrumb label={I18n.t('current folder path')}>
          {path.map((currentFolder, i) => {
            // special case to make the last folder in the path (i.e. the current folder)
            // not a link
            if (i === path.length - 1) {
              return (
                <BreadcrumbLinkWithTip key={currentFolder.id} tip={currentFolder.name}>
                  {currentFolder.name}
                </BreadcrumbLinkWithTip>
              )
            }
            return (
              <BreadcrumbLinkWithTip
                key={currentFolder.id}
                tip={currentFolder.name}
                onClick={() => this.handleUpdateSelectedFolder(currentFolder.id)}
              >
                {currentFolder.name}
              </BreadcrumbLinkWithTip>
            )
          })}
        </Breadcrumb>
      </Flex.Item>
    )
  }

  render() {
    if (this.state.error) {
      return (
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorSubject={this.state.error.message}
          errorCategory={I18n.t('Assignments 2 Student Error Page')}
        />
      )
    }

    return (
      <Flex direction="column" data-testid="more-options-file-select">
        {this.renderFolderPathBreadcrumb()}
        <Flex.Item>
          <FileSelectTable
            allowedExtensions={this.props.allowedExtensions}
            folders={this.state.loadedFolders}
            files={this.state.loadedFiles}
            selectedFolderID={this.state.selectedFolderID}
            handleCanvasFileSelect={this.props.handleCanvasFileSelect}
            handleFolderSelect={this.handleUpdateSelectedFolder}
          />
        </Flex.Item>
        {this.state.pendingAPIRequests && (
          <Flex.Item>
            <LoadingIndicator />
          </Flex.Item>
        )}
      </Flex>
    )
  }
}

CanvasFiles.propTypes = {
  allowedExtensions: arrayOf(string),
  courseID: string.isRequired,
  handleCanvasFileSelect: func.isRequired,
  userGroups: arrayOf(
    shape({
      _id: string,
      name: string,
    })
  ),
}

export default CanvasFiles
