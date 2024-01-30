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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import _ from 'lodash'
import $ from 'jquery'
import axios from '@canvas/axios'
import minimatch from 'minimatch'
import {TreeBrowser} from '@instructure/ui-tree-browser'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Button} from '@instructure/ui-buttons'
import {Mask} from '@instructure/ui-overlays'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import splitAssetString from '@canvas/util/splitAssetString'
import {
  IconOpenFolderSolid,
  IconFolderSolid,
  IconUploadSolid,
  IconImageSolid,
} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import {getRootFolder, uploadFile} from '@canvas/files/util/apiFileUtils'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import natcompare from '@canvas/util/natcompare'
import { captureException } from '@sentry/react'

const I18n = useI18nScope('react_files')

class FileBrowser extends React.Component {
  static propTypes = {
    allowUpload: PropTypes.bool,
    contentTypes: PropTypes.arrayOf(PropTypes.string),
    defaultUploadFolderId: PropTypes.string,
    selectFile: PropTypes.func.isRequired,
    useContextAssets: PropTypes.bool,
  }

  static defaultProps = {
    allowUpload: true,
    contentTypes: ['*/*'],
    defaultUploadFolderId: null,
    useContextAssets: true,
  }

  constructor(props) {
    super(props)
    this.state = {
      collections: {0: {id: 0, collections: []}},
      items: {},
      openFolders: [],
      uploadFolder: null,
      uploading: false,
      loadingCount: 0,
    }
  }

  componentDidMount() {
    this.getRootFolders()
  }

  getContextName(contextType) {
    if (contextType === 'courses') {
      return I18n.t('Course files')
    } else {
      return I18n.t('Group files')
    }
  }

  getContextInfo(assetString) {
    const contextTypeAndId = splitAssetString(assetString)
    if (contextTypeAndId && contextTypeAndId[0] && contextTypeAndId[1]) {
      const contextName = this.getContextName(contextTypeAndId[0])
      return {name: contextName, type: contextTypeAndId[0], id: contextTypeAndId[1]}
    }
  }

  getRootFolders() {
    if (this.props.useContextAssets) {
      this.getContextFolders()
    }
    this.getUserFolders()
  }

  getUserFolders() {
    this.getRootFolderData('users', 'self', {name: I18n.t('My files')})
  }

  getContextFolders() {
    if (!ENV.context_asset_string) return
    const contextInfo = this.getContextInfo(ENV.context_asset_string)
    if (contextInfo && contextInfo.type && contextInfo.id) {
      this.getRootFolderData(contextInfo.type, contextInfo.id, {name: contextInfo.name})
    }
  }

  increaseLoadingCount() {
    let {loadingCount} = this.state
    loadingCount += 1
    this.setState({loadingCount})
  }

  decreaseLoadingCount() {
    let {loadingCount} = this.state
    loadingCount -= 1
    this.setState({loadingCount})
  }

  getRootFolderData(context, id, opts = {}) {
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

  populateRootFolder(data, opts = {}) {
    this.decreaseLoadingCount()
    this.populateCollectionsList([data], opts)
    this.getFolderData(data.id)
  }

  getFolderData(id) {
    const {collections} = this.state
    if (!collections[id].locked) {
      this.getPaginatedData(this.folderFileApiUrl(id, 'folders'), this.populateCollectionsList)
      this.getPaginatedData(this.folderFileApiUrl(id), this.populateItemsList)
    }
  }

  getPaginatedData(url, callback) {
    axios
      .get(url)
      .then(response => {
        callback(response.data)
        const nextUrl = parseLinkHeader(response.headers.link).next
        if (nextUrl) {
          this.getPaginatedData(nextUrl, callback)
        }
      })
      .catch(error => {
        /* eslint-disable no-console */
        console.error('Error fetching data from API')
        console.error(error)
        captureException(error)
        /* eslint-enable no-console */
      })
  }

  folderFileApiUrl(folderId, type = 'files') {
    return `/api/v1/folders/${folderId}/${type}`
  }

  populateCollectionsList = (folderList, opts = {}) => {
    this.setState(function ({collections}) {
      const newCollections = _.cloneDeep(collections)
      folderList.forEach(folder => {
        const collection = this.formatFolderInfo(folder, opts)
        newCollections[collection.id] = collection
        const parent_id = folder.parent_folder_id || 0
        const collectionCollections = newCollections[parent_id].collections
        if (!collectionCollections.includes(collection.id)) {
          collectionCollections.push(collection.id)
          newCollections[parent_id].collections = this.orderedIdsFromList(
            newCollections,
            collectionCollections
          )
        }
      })
      return {collections: newCollections}
    })

    folderList.forEach(folder => {
      if (this.state.openFolders.includes(folder.parent_folder_id)) {
        this.getFolderData(folder.id)
      }
    })
  }

  contentTypeIsAllowed(contentType) {
    for (const pattern of this.props.contentTypes) {
      if (minimatch(contentType, pattern)) {
        return true
      }
    }
    return false
  }

  populateItemsList = fileList => {
    this.setState(function ({items, collections}) {
      const newItems = _.cloneDeep(items)
      const newCollections = _.cloneDeep(collections)
      fileList.forEach(file => {
        if (this.contentTypeIsAllowed(file['content-type'])) {
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
      return {items: newItems, collections: newCollections}
    })
  }

  formatFolderInfo(apiFolder, opts = {}) {
    const descriptor = apiFolder.locked_for_user ? I18n.t('Locked') : null
    const folder = {
      api: apiFolder,
      id: apiFolder.id,
      collections: [],
      items: [],
      name: apiFolder.name,
      context: `/${apiFolder.context_type.toLowerCase()}s/${apiFolder.context_id}`,
      canUpload: apiFolder.can_upload,
      locked: apiFolder.locked_for_user,
      descriptor,
      ...opts,
    }
    const existingCollections = this.state.collections[apiFolder.id]
    Object.assign(
      folder,
      existingCollections && {
        collections: existingCollections.collections,
        items: existingCollections.items,
      }
    )
    return folder
  }

  formatFileInfo(apiFile, opts = {}) {
    const {collections} = this.state
    const context = collections[apiFile.folder_id].context
    const file = {
      api: apiFile,
      id: apiFile.id,
      name: apiFile.display_name,
      thumbnail: apiFile.thumbnail_url,
      src: `${context}/files/${apiFile.id}/preview${
        context.includes('user') ? `?verifier=${apiFile.uuid}` : ''
      }`,
      alt: apiFile.display_name,
      ...opts,
    }
    return file
  }

  orderedIdsFromList(list, ids) {
    try {
      const sortedIds = ids.sort((a, b) => natcompare.strings(list[a].name, list[b].name))
      return sortedIds
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(error)
      captureException(error)
      return ids
    }
  }

  uploadFolderId = () => {
    return this.state.uploadFolder || this.props.defaultUploadFolderId
  }

  onFolderToggle = folder => {
    return this.onFolderClick(folder.id, folder)
  }

  onFolderClick = (folderId, _folder) => {
    const collection = this.state.collections[folderId]
    let newFolders = []
    const {openFolders} = this.state
    if (!collection.locked && openFolders.includes(folderId)) {
      newFolders = newFolders.concat(openFolders.filter(id => id !== folderId))
    } else if (!collection.locked) {
      newFolders = newFolders.concat(openFolders)
      newFolders.push(folderId)
      collection.collections.forEach(id => this.getFolderData(id))
    }
    return this.setState({openFolders: newFolders, uploadFolder: folderId})
  }

  onFileClick = file => {
    const folder = this.findFolderForFile(file)
    this.setState({uploadFolder: folder && folder.id})
    this.props.selectFile(this.state.items[file.id])
  }

  onInputChange = files => {
    if (files) {
      this.submitFile(files[0])
    }
  }

  submitFile = file => {
    this.setState({uploading: true})
    uploadFile(file, this.uploadFolderId(), this.onUploadSucceed, this.onUploadFail)
  }

  onUploadSucceed = response => {
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

  findFolderForFile(file) {
    const {collections} = this.state
    const folderKey = Object.keys(collections).find(key => {
      const items = collections[key].items
      if (items && items.includes(file.id)) return key
      return false
    })
    return collections[folderKey]
  }

  onUploadFail = () => {
    this.clearUploadInfo()
    this.setFailureMessage(I18n.t('File upload failed'))
  }

  clearUploadInfo() {
    this.setState({uploading: false})
    this.uploadInput.value = ''
  }

  setSuccessMessage = message => {
    showFlashSuccess(message)()
  }

  setFailureMessage = message => {
    showFlashError(message)()
  }

  selectLocalFile = () => {
    this.uploadInput.click()
  }

  renderUploadDialog() {
    if (!this.props.allowUpload) {
      return null
    }
    const uploadFolder = this.state.collections[this.uploadFolderId()]
    const disabled = !uploadFolder || uploadFolder.locked || !uploadFolder.canUpload
    const srError = disabled ? (
      <ScreenReaderContent>{I18n.t('Upload not available for this folder')}</ScreenReaderContent>
    ) : (
      ''
    )
    const acceptContentTypes = this.props.contentTypes.join(',')
    return (
      <div className="image-upload__form">
        <input
          onChange={e => this.onInputChange(e.target.files)}
          ref={i => {
            this.uploadInput = i
          }}
          type="file"
          accept={acceptContentTypes}
          className="hidden"
        />
        <Button
          id="image-upload__upload"
          onClick={this.selectLocalFile}
          disabled={disabled}
          color="primary"
          withBackground={false}
          renderIcon={IconUploadSolid}
        >
          {I18n.t('Upload File')} {srError}
        </Button>
      </div>
    )
  }

  renderMask() {
    if (this.state.uploading) {
      return (
        <Mask>
          <Spinner renderTitle={I18n.t('File uploading')} />
        </Mask>
      )
    } else {
      return null
    }
  }

  renderLoading() {
    if (this.state.loadingCount > 0) {
      return <Spinner renderTitle={I18n.t('Loading folders')} size="small" />
    } else {
      return null
    }
  }

  render() {
    const element = (
      <div className="file-browser__container">
        <Text>{I18n.t('Available folders')}</Text>
        <div className="file-browser__tree">
          <TreeBrowser
            collections={this.state.collections}
            items={this.state.items}
            size="medium"
            onCollectionToggle={this.onFolderToggle}
            onCollectionClick={this.onFolderClick}
            onItemClick={this.onFileClick}
            treeLabel={I18n.t('Folder tree')}
            rootId={0}
            showRootCollection={false}
            defaultExpanded={this.state.openFolders}
            collectionIconExpanded={IconOpenFolderSolid}
            collectionIcon={IconFolderSolid}
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
