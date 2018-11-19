// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!react_files'
import React from 'react'
import _ from 'lodash'
import $ from 'jquery'
import axios from 'axios'
import TreeBrowser from '@instructure/ui-tree-browser/lib/components/TreeBrowser'
import Text from '@instructure/ui-elements/lib/components/Text'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Mask from '@instructure/ui-overlays/lib/components/Mask'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import splitAssetString from 'compiled/str/splitAssetString'
import IconOpenFolderSolid from '@instructure/ui-icons/lib/Solid/IconOpenFolder'
import IconUploadSolid from '@instructure/ui-icons/lib/Solid/IconUpload'
import IconImageSolid from '@instructure/ui-icons/lib/Solid/IconImage'
import { string, func } from 'prop-types';
import { getRootFolder, uploadFile } from 'jsx/files/utils/apiFileUtils'
import parseLinkHeader from '../parseLinkHeader'
import { showFlashSuccess, showFlashError } from '../FlashAlert'
import natcompare from '../../../coffeescripts/util/natcompare'
/* eslint-disable react/sort-comp */

class FileBrowser extends React.Component {
  static propTypes = {
    selectFile: func.isRequired,
    type: string,
  }

  static defaultProps = {
    type: '*',
  }

  constructor (props) {
    super(props);
    this.state = {
      collections: {0: {collections: []}},
      items: {},
      openFolders: [],
      uploadFolder: null,
      uploading: false,
      loadingCount: 0,
    }
  }

  componentDidMount () {
    this.getRootFolders()
  }

  getContextInfo (assetString) {
    const contextTypeAndId = splitAssetString(ENV.context_asset_string)
    if (contextTypeAndId[0] && contextTypeAndId[1]) {
      const contextName = contextTypeAndId[0] === 'courses' ? I18n.t('Course files') : I18n.t('Group files')
      return {name: contextName, type: contextTypeAndId[0], id: contextTypeAndId[1]}
    }
  }

  getRootFolders () {
    const contextInfo = this.getContextInfo(ENV.context_asset_string)
    if (contextInfo.type && contextInfo.id) {
      this.getRootFolderData(contextInfo.type, contextInfo.id, {name: contextInfo.name})
    }
    this.getRootFolderData('users', 'self', {name: I18n.t('My files')})
  }

  increaseLoadingCount () {
    let { loadingCount } = this.state
    loadingCount += 1
    this.setState({loadingCount})
  }

  decreaseLoadingCount () {
    let { loadingCount } = this.state
    loadingCount -= 1
    this.setState({loadingCount})
  }

  getRootFolderData (context, id, opts = {}) {
    this.increaseLoadingCount()
    getRootFolder(context, id)
      .then(response => this.populateRootFolder(response.data, opts))
      .catch(error => {
        this.decreaseLoadingCount()
        if (error.response && error.response.status !== 401) {
          this.setFailureMessage(I18n.t('Something went wrong'))
        }
      })
  }

  populateRootFolder (data, opts = {}) {
    this.decreaseLoadingCount()
    this.populateCollectionsList([data], opts)
    this.getFolderData(data.id)
  }

  getFolderData (id) {
    const { collections } = this.state
    if (!collections[id].locked) {
      this.getPaginatedData(this.folderFileApiUrl(id, 'folders'), this.populateCollectionsList)
      this.getPaginatedData(this.folderFileApiUrl(id), this.populateItemsList)
    }
  }

  getPaginatedData (url, callback) {
    axios.get(url)
      .then(response => {
        callback(response.data)
        const nextUrl = parseLinkHeader(response.headers.link).next
        if (nextUrl) {
          this.getPaginatedData(nextUrl, callback)
        }
      })
  }

  folderFileApiUrl (folderId, type='files') {
    return `/api/v1/folders/${folderId}/${type}`
  }

  populateCollectionsList = (folderList, opts = {}) => {
    const newCollections = _.cloneDeep(this.state.collections)
    folderList.forEach((folder) => {
      const collection = this.formatFolderInfo(folder, opts)
      newCollections[collection.id] = collection
      const parent_id = folder.parent_folder_id || 0
      const collectionCollections = newCollections[parent_id].collections
      if (!collectionCollections.includes(collection.id)) {
        collectionCollections.push(collection.id)
        newCollections[parent_id].collections = this.orderedIdsFromList(newCollections, collectionCollections)
      }
    })
    this.setState({collections: newCollections})
    folderList.forEach(folder => {
      if (this.state.openFolders.includes(folder.parent_folder_id)) this.getFolderData(folder.id)
    })
  }

  populateItemsList = (fileList) => {
    const newItems = _.cloneDeep(this.state.items)
    const newCollections = _.cloneDeep(this.state.collections)
    fileList.forEach((file) => {
      if (file["content-type"].match(new RegExp(this.props.type))) {
        const item = this.formatFileInfo(file)
        newItems[item.id] = item
        const folder_id = file.folder_id
        const collectionItems = newCollections[folder_id].items
        if (!collectionItems.includes(item.id)) {
          collectionItems.push(item.id)
          newCollections[folder_id].items = this.orderedIdsFromList(newItems, collectionItems)
        }
      }
    })
    this.setState({items: newItems, collections: newCollections})
  }

  formatFolderInfo (apiFolder, opts = {}) {
    const descriptor = apiFolder.locked_for_user ? I18n.t('Locked') : null
    const folder = {
      id: apiFolder.id,
      collections: [],
      items: [],
      name: apiFolder.name,
      context: `/${apiFolder.context_type.toLowerCase()}s/${apiFolder.context_id}`,
      canUpload: apiFolder.can_upload,
      locked: apiFolder.locked_for_user,
      descriptor,
      ...opts
    }
    const existingCollections = this.state.collections[apiFolder.id]
    Object.assign(folder, existingCollections && {
      collections: existingCollections.collections,
      items: existingCollections.items
    })
    return folder
  }

  formatFileInfo (apiFile, opts = {}) {
    const { collections } = this.state
    const context = collections[apiFile.folder_id].context
    const file = {
      id: apiFile.id,
      name: apiFile.display_name,
      src: `${context}/files/${apiFile.id}/preview${context.includes('user') ? `?verifier=${apiFile.uuid}` : ''}`,
      alt: apiFile.display_name,
      ...opts
    }
    return file
  }

  orderedIdsFromList (list, ids) {
    try {
      const sortedIds = ids.sort((a, b) => natcompare.strings(list[a].name, list[b].name))
      return sortedIds
    }
    catch(error) {
      console.error(error)
      return ids
    }
  }

  onFolderClick = (folderId) => {
    const collection = this.state.collections[folderId]
    let newFolders = []
    const { openFolders } = this.state
    if (!collection.locked && openFolders.includes(folderId)) {
      newFolders = newFolders.concat(openFolders.filter(id => id !== folderId))
    } else if (!collection.locked) {
      newFolders = newFolders.concat(openFolders)
      newFolders.push(folderId)
      collection.collections.forEach(folder => this.getFolderData(folder))
    }
    return this.setState({openFolders: newFolders, uploadFolder: folderId})
  }

  onFileClick = (file) => {
    const folder = this.findFolderForFile(file)
    this.setState({uploadFolder: folder && folder.id})
    this.props.selectFile(this.state.items[file.id])
  }

  onInputChange = (files) => {
    if (files) {
      this.submitFile(files[0])
    }
  }

  submitFile = (file) => {
    this.setState({uploading: true})
    uploadFile(file, this.state.uploadFolder,
      this.onUploadSucceed,
      this.onUploadFail)
  }

  onUploadSucceed = (response) => {
    this.populateItemsList([response])
    this.clearUploadInfo()
    const folder = this.state.collections[response.folder_id]
    this.setSuccessMessage(I18n.t('Success: File uploaded'))
    if ($(`button:contains('${response.display_name}')`).length === 0) {
      $(`button:contains('${folder && folder.name}')`).click()
    }
    const button = $(`button:contains('${response.display_name}')`)
    $('.file-browser__tree').scrollTo(button)
    button.click()
  }

  findFolderForFile (file) {
    const { collections}  = this.state
    const folderKey = Object.keys(collections).find((key) => {
      const items = collections[key].items
      if (items && items.includes(file.id)) return key
    })
    return collections[folderKey]
  }

  onUploadFail = () => {
    this.clearUploadInfo()
    this.setFailureMessage(I18n.t('File upload failed'))
  }

  clearUploadInfo () {
    this.setState({uploading: false})
    this.uploadInput.value = ''
  }

  setSuccessMessage = (message) => {
    showFlashSuccess(message)()
  }

  setFailureMessage = (message) => {
    showFlashError(message)()
  }

  selectLocalFile = () => {
    this.uploadInput.click()
  }

  renderUploadDialog () {
    const uploadFolder = this.state.collections[this.state.uploadFolder]
    const disabled = !uploadFolder || uploadFolder.locked || !uploadFolder.canUpload
    const srError = disabled ? <ScreenReaderContent>{I18n.t('Upload not available for this folder')}</ScreenReaderContent> : ''
    return (
      <div className="image-upload__form">
        <input
          onChange={(e) => this.onInputChange(e.target.files)}
          ref={i => {this.uploadInput = i}}
          type="file"
          accept={this.props.type}
          className="hidden"
        />
        <Button id="image-upload__upload" onClick={this.selectLocalFile} disabled={disabled} variant="ghost" icon={IconUploadSolid}>
          {I18n.t('Upload File')} {srError}
        </Button>
      </div>
    )
  }

  renderMask () {
    if (this.state.uploading) {
      return <Mask><Spinner className="file-browser__uploading" title={I18n.t('File uploading')} /></Mask>
    } else {
      return null
    }
  }

  renderLoading () {
    if (this.state.loadingCount > 0) {
      return <Spinner className="file-browser__loading" title={I18n.t('Loading folders')} size="small" />
    } else {
      return null
    }
  }

  render () {
    const element = (
      <div className="file-browser__container">
        <Text>{I18n.t('Available folders')}</Text>
        <div className="file-browser__tree">
          <TreeBrowser
            collections={this.state.collections}
            items={this.state.items}
            size="medium"
            onCollectionClick={this.onFolderClick}
            onItemClick={this.onFileClick}
            treeLabel={I18n.t('Folder tree')}
            rootId={0}
            showRootCollection={false}
            defaultExpanded={this.state.openFolders}
            collectionIconExpanded={IconOpenFolderSolid}
            itemIcon={IconImageSolid}
            selectionType="single"
          />
          {this.renderMask()}
          {this.renderLoading()}
        </div>
        {this.renderUploadDialog()}
      </div>
    )
    return element
  }
}

export default FileBrowser
/* eslint-enable react/sort-comp */
