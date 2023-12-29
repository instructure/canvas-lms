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

import React from 'react'
import formatMessage from '../format-message'
import _ from 'lodash'
import minimatch from 'minimatch'
import {TreeBrowser} from '@instructure/ui-tree-browser'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {IconOpenFolderSolid, IconFolderSolid, IconImageLine} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import {getIconFromType, isImage} from '../rce/plugins/shared/fileTypeUtils'
import {showFlashError} from '../common/FlashAlert'
import natcompare from '../common/natcompare'

export const PENDING_MEDIA_ENTRY_ID = 'maybe'

class FileBrowser extends React.Component {
  static propTypes = {
    allowUpload: PropTypes.bool,
    selectFile: PropTypes.func.isRequired,
    contentTypes: PropTypes.arrayOf(PropTypes.string),
    useContextAssets: PropTypes.bool,
    searchString: PropTypes.string,
    onLoading: PropTypes.func.isRequired,
    context: PropTypes.shape({
      type: PropTypes.string.isRequired,
      id: PropTypes.string.isRequired,
    }).isRequired,
  }

  static defaultProps = {
    allowUpload: true,
    contentTypes: ['*/*'],
    useContextAssets: true,
  }

  constructor(props) {
    super(props)
    this.state = {
      collections: {0: {id: 0, collections: []}},
      items: {},
      openFolders: [],
      loadingCount: 0,
    }

    this.source = props.source
    this.updatePropsWithThumbnailOrIcon = this.updatePropsWithThumbnailOrIcon.bind(this)
  }

  componentDidMount() {
    this.getRootFolders()
  }

  componentDidUpdate() {
    this.state.openFolders.forEach(fid => {
      if (this.props.searchString !== this.state.collections[fid].searchString) {
        this.getFolderData(fid)
      }
    })
  }

  getContextName(contextType) {
    if (contextType === 'course') {
      return formatMessage('Course files')
    } else {
      return formatMessage('Group files')
    }
  }

  getRootFolders() {
    if (this.props.useContextAssets) {
      this.getContextFolders()
    }
    this.getUserFolders()
  }

  getUserFolders() {
    this.getRootFolderData('user', 'self', {name: formatMessage('My files')})
  }

  getContextFolders() {
    const {type, id} = this.props.context
    if (type && id) {
      this.getRootFolderData(type, id, {name: this.getContextName(type)})
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

  getRootFolderData(context, contextId, opts = {}) {
    this.increaseLoadingCount()

    this.source
      .fetchRootFolder({
        contextType: context,
        contextId,
      })
      .then(result => {
        this.populateRootFolder(result.folders[0], opts)
      })
      .catch(error => {
        this.decreaseLoadingCount()
        if (error.response && error.response.status !== 401) {
          this.setFailureMessage(formatMessage('Something went wrong'))
        }
      })
  }

  populateRootFolder(data, opts = {}) {
    this.decreaseLoadingCount()
    this.populateCollectionsList([data], opts)
    this.getFolderData(data.id)
  }

  // Memoized function to fetch all subfolders
  // of the given folder ID, handing pagination
  fetchSubFolders = _.memoize(id => {
    this.source.fetchBookmarkedData(
      this.source.fetchSubFolders.bind(this.source),
      {
        folderId: id,
        perPage: 50,
      },
      result => {
        this.populateCollectionsList(result.folders)
      },
      error => {
        this.props.onLoading(false)
        /* eslint-disable no-console */
        console.error('Error fetching data from API')
        console.error(error)
      }
    )
  })

  fetchFiles(id) {
    this.source.fetchBookmarkedData(
      this.source.fetchFilesForFolder.bind(this.source),
      {
        searchString: this.props.searchString,
        perPage: 50,
        filesUrl: this.state.collections[id]?.api?.filesUrl,
      },
      result => {
        this.populateItemsList(result.files)
      },
      error => {
        this.props.onLoading(false)
        console.error(error)
      }
    )
  }

  getFolderData(id) {
    if (!this.state.collections[id].locked) {
      this.setState(
        (state, _props) => {
          const collections = {...state.collections}
          const collection = {...collections[id]}
          collection.items = []
          collection.searchString = this.props.searchString
          collections[id] = collection
          return {collections}
        },
        () => {
          this.fetchSubFolders(id)
          this.fetchFiles(id)
        }
      )
    }
  }

  populateCollectionsList = (folderList, opts = {}) => {
    this.setState((state, props) => {
      const newCollections = _.cloneDeep(state.collections)
      folderList.forEach(folder => {
        const collection = this.formatFolderInfo(folder, {
          ...opts,
          searchString: props.searchString,
        })
        newCollections[collection.id] = collection
        const parentId = folder.parentId || 0
        const collectionCollections = newCollections[parentId].collections
        if (!collectionCollections.includes(collection.id)) {
          collectionCollections.push(collection.id)
          newCollections[parentId].collections = this.orderedIdsFromList(
            newCollections,
            collectionCollections
          )
        }
      })
      return {collections: newCollections}
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
    this.setState((state, _props) => {
      const newItems = _.cloneDeep(state.items)
      const newCollections = _.cloneDeep(state.collections)
      fileList.forEach(file => {
        if (this.contentTypeIsAllowed(file.type)) {
          const item = this.formatFileInfo(file)
          newItems[item.id] = item
          const folder_id = file.folderId
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
    const descriptor = apiFolder.lockedForUser ? formatMessage('Locked') : null
    const folder = {
      api: apiFolder,
      id: apiFolder.id,
      collections: [],
      items: [],
      name: apiFolder.name,
      context: `/${apiFolder.contextType?.toLowerCase()}s/${apiFolder.contextId}`,
      canUpload: apiFolder.canUpload,
      locked: apiFolder.lockedForUser,
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

  updatePropsWithThumbnailOrIcon(props) {
    const {id} = props
    const file = this.state.items[id].api

    let thumbnail, itemIcon
    if (isImage(file.type)) {
      if (file.thumbnailUrl) {
        thumbnail = file.thumbnailUrl
      } else {
        itemIcon = IconImageLine
      }
    } else {
      itemIcon = getIconFromType(file.type)
    }
    const containerRef = node => {
      if (node && !node.title && props.name) node.title = props.name
    }

    return {...props, thumbnail, itemIcon, containerRef}
  }

  formatFileInfo(apiFile, opts = {}) {
    const {collections} = this.state
    const context = collections[apiFile.folderId].context
    const isMediaPending = apiFile.mediaEntryId === PENDING_MEDIA_ENTRY_ID
    const file = {
      api: apiFile,
      id: apiFile.id,
      name: apiFile.name,
      isDisabled: isMediaPending,
      src: `${context}/files/${apiFile.id}/preview${
        context.includes('user') ? `?verifier=${apiFile.uuid}` : ''
      }`,
      alt: apiFile.name,
      ...opts,
    }
    if (apiFile.iframeUrl) {
      // it's a media_object
      file.src = apiFile.iframeUrl
    }
    if (isMediaPending) {
      file.descriptor = formatMessage('Media file is processing. Please try again later.')
    }
    return file
  }

  orderedIdsFromList(list, ids) {
    try {
      const sortedIds = ids.sort((a, b) => natcompare.strings(list[a].name, list[b].name))
      return sortedIds
    } catch (error) {
      console.error(error)
      return ids
    }
  }

  onFolderToggle = folder => {
    const folderId = folder.id
    this.setState(
      (state, _props) => {
        const collection = state.collections[folderId]
        let newFolders = []
        let newCollections = state.collections
        const {openFolders} = state
        if (!collection.locked && openFolders.includes(folderId)) {
          newFolders = newFolders.concat(openFolders.filter(id => id !== folderId))
        } else if (!collection.locked) {
          newFolders = newFolders.concat(openFolders)
          newFolders.push(folderId)
          newCollections = _.cloneDeep(state.collections)
          newCollections[folderId] = collection
        }
        return {openFolders: newFolders, uploadFolder: folderId, collections: newCollections}
      },
      () => {
        if (this.state.openFolders.includes(folderId)) {
          const collection = this.state.collections[folderId]
          if (!collection.locked) {
            this.getFolderData(folderId)
          }
        }
      }
    )
  }

  onFileClick = file => {
    const selectedItem = this.state.items[file.id]
    if (selectedItem.isDisabled) return

    this.props.selectFile(selectedItem)
  }

  findFolderForFile(file) {
    const {collections} = this.state
    const folderKey = Object.keys(collections).find(key => {
      const items = collections[key].items
      return items && items.includes(file.id)
    })
    return collections[folderKey]
  }

  setFailureMessage = message => {
    showFlashError(message)()
  }

  renderLoading() {
    if (this.state.loadingCount > 0) {
      return <Spinner renderTitle={formatMessage('Loading folders')} size="small" />
    } else {
      return null
    }
  }

  render() {
    const element = (
      <div className="file-browser__container">
        <Text>{formatMessage('Available folders')}</Text>
        <div className="file-browser__tree">
          <TreeBrowser
            collections={this.state.collections}
            items={this.state.items}
            size="medium"
            onCollectionToggle={this.onFolderToggle}
            onItemClick={this.onFileClick}
            treeLabel={formatMessage('Folder tree')}
            rootId={0}
            showRootCollection={false}
            expanded={this.state.openFolders}
            collectionIconExpanded={IconOpenFolderSolid}
            collectionIcon={IconFolderSolid}
            selectionType="single"
            getItemProps={this.updatePropsWithThumbnailOrIcon}
          />
          {this.renderLoading()}
        </div>
      </div>
    )
    return element
  }
}

export default FileBrowser
