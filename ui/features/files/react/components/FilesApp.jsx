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

import $ from 'jquery'
import React from 'react'
import createReactClass from 'create-react-class'
import page from 'page'
import FilesApp from '../legacy/components/FilesApp'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import {useScope as useI18nScope} from '@canvas/i18n'
import Breadcrumbs from './Breadcrumbs'
import FolderTree from './FolderTree'
import FilesUsage from './FilesUsage'
import Toolbar from './Toolbar'

const I18n = useI18nScope('react_files')

FilesApp.previewItem = function (item) {
  this.clearSelectedItems(() => {
    this.toggleItemSelected(item, null, () => {
      const queryString = $.param(this.getPreviewQuery())
      page(`${this.getPreviewRoute()}?${queryString}`)
    })
  })
}

FilesApp.getPreviewRoute = function () {
  if (this.props.query && this.props.query.search_term) {
    return '/search'
  } else if (this.props.splat) {
    return `/folder/${this.props.splat}`
  } else {
    return ''
  }
}

FilesApp.render = function () {
  let contextType
  let contextId

  // when showing a folder
  if (this.state.currentFolder) {
    contextType = `${this.state.currentFolder.get('context_type').toLowerCase()}s`
    contextId = this.state.currentFolder.get('context_id')
  } else {
    // when showing search results
    contextType = filesEnv.contextType
    contextId = filesEnv.contextId
  }

  const canManageFilesForContext = permission => {
    return filesEnv.userHasPermission({contextType, contextId}, permission)
  }

  const userCanAddFilesForContext = canManageFilesForContext('manage_files_add')
  const userCanEditFilesForContext = canManageFilesForContext('manage_files_edit')
  const userCanDeleteFilesForContext = canManageFilesForContext('manage_files_delete')
  const userCanManageFilesForContext =
    userCanAddFilesForContext || userCanEditFilesForContext || userCanDeleteFilesForContext
  const userCanRestrictFilesForContext = userCanEditFilesForContext && contextType !== 'groups'
  const usageRightsRequiredForContext = filesEnv.contextsDictionary[`${contextType}_${contextId}`]
    ? filesEnv.contextsDictionary[`${contextType}_${contextId}`].usage_rights_required
    : false
  const externalToolsForContext = filesEnv.contextFor({contextType, contextId})
    ? filesEnv.contextFor({contextType, contextId}).file_menu_tools
    : []
  const indexExternalToolsForContext = filesEnv.contextFor({contextType, contextId})
    ? filesEnv.contextFor({contextType, contextId}).file_index_menu_tools
    : []

  return (
    <div>
      {/* For whatever reason, VO in Safari didn't like just the h1 tag.
            Sometimes it worked, others it didn't, this makes it work always */}
      <header>
        <h1 className="screenreader-only">{I18n.t('Files')}</h1>
      </header>
      {!window.ENV.K5_SUBJECT_COURSE && (
        <div className="ic-app-nav-toggle-and-crumbs ic-app-nav-toggle-and-crumbs--files no-print">
          <button
            className="Button Button--link ic-app-course-nav-toggle"
            type="button"
            id="courseMenuToggle"
            aria-label={I18n.t('Show and hide courses menu')}
            aria-hidden={true}
          >
            <i className="icon-hamburger" aria-hidden="true" />
          </button>
          <div className="ic-app-crumbs">
            <Breadcrumbs
              rootTillCurrentFolder={this.state.rootTillCurrentFolder}
              showingSearchResults={this.state.showingSearchResults}
              query={this.props.query}
              contextAssetString={this.props.contextAssetString}
            />
          </div>
          <div className="TutorialToggleHolder" />
        </div>
      )}
      <Toolbar
        currentFolder={this.state.currentFolder}
        query={this.props.query}
        selectedItems={this.state.selectedItems}
        clearSelectedItems={this.clearSelectedItems}
        onMove={this.onMove}
        contextType={contextType}
        contextId={contextId}
        userCanAddFilesForContext={userCanAddFilesForContext}
        userCanEditFilesForContext={userCanEditFilesForContext}
        userCanDeleteFilesForContext={userCanDeleteFilesForContext}
        usageRightsRequiredForContext={usageRightsRequiredForContext}
        userCanRestrictFilesForContext={userCanRestrictFilesForContext}
        indexExternalToolsForContext={indexExternalToolsForContext}
        getPreviewQuery={this.getPreviewQuery}
        getPreviewRoute={this.getPreviewRoute}
        modalOptions={{
          isOpen: this.state.showingModal,
          openModal: this.openModal,
          closeModal: this.closeModal,
        }}
        showingSearchResults={this.state.showingSearchResults}
      />
      <div className="ef-main">
        <aside
          className="visible-desktop ef-folder-content"
          role="region"
          aria-label={I18n.t('Folder Browsing Tree')}
        >
          <FolderTree
            rootTillCurrentFolder={this.state.rootTillCurrentFolder}
            rootFoldersToShow={filesEnv.rootFolders}
            dndOptions={{
              onItemDragEnterOrOver: this.onItemDragEnterOrOver,
              onItemDragLeaveOrEnd: this.onItemDragLeaveOrEnd,
              onItemDrop: this.onItemDrop,
            }}
          />
        </aside>
        <div
          className="ef-directory"
          role="region"
          aria-label={I18n.t('File List')}
          ref={e => (this.filesDirectory = e)}
        >
          {React.cloneElement(this.props.children, {
            key: this.state.key,
            pathname: this.props.pathname,
            splat: this.props.splat,
            query: this.props.query,
            params: this.props.params,
            onResolvePath: this.onResolvePath,
            currentFolder: this.state.currentFolder,
            contextType,
            contextId,
            selectedItems: this.state.selectedItems,
            toggleItemSelected: this.toggleItemSelected,
            toggleAllSelected: this.toggleAllSelected,
            areAllItemsSelected: this.areAllItemsSelected,
            userCanAddFilesForContext,
            userCanEditFilesForContext,
            userCanDeleteFilesForContext,
            userCanRestrictFilesForContext,
            usageRightsRequiredForContext,
            externalToolsForContext,
            previewItem: this.previewItem,
            onMove: this.onMove,
            modalOptions: {
              isOpen: this.state.showingModal,
              openModal: this.openModal,
              closeModal: this.closeModal,
            },
            dndOptions: {
              onItemDragStart: this.onItemDragStart,
              onItemDragEnterOrOver: this.onItemDragEnterOrOver,
              onItemDragLeaveOrEnd: this.onItemDragLeaveOrEnd,
              onItemDrop: this.onItemDrop,
            },
            clearSelectedItems: this.clearSelectedItems,
            filesDirectoryRef: this.filesDirectory,
          })}
        </div>
      </div>
      <div className="ef-footer grid-row">
        {userCanManageFilesForContext && (
          <div className="col-xs-6">
            <FilesUsage className="col-xs-4" contextType={contextType} contextId={contextId} />
          </div>
        )}
        {!filesEnv.showingAllContexts && (
          <div className="col-xs-6">
            <div>
              <a className="pull-right" href="/files">
                {I18n.t('All My Files')}
              </a>
            </div>
          </div>
        )}
      </div>
      {this.state.showingModal && this.state.modalContents}
    </div>
  )
}

export default createReactClass(FilesApp)
