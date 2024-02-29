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
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'
import page from 'page'
import FocusStore from '../legacy/modules/FocusStore'
import openMoveDialog from '../../openMoveDialog'
import deleteStuff from '../legacy/util/deleteStuff'
import UploadButton from './UploadButton'
import classnames from 'classnames'
import preventDefault from '@canvas/util/preventDefault'
import Folder from '@canvas/files/backbone/models/Folder'
import PropTypes from 'prop-types'
import UsageRightsDialog from '@canvas/files/react/components/UsageRightsDialog'
import downloadStuffAsAZip from '../legacy/util/downloadStuffAsAZip'
import customPropTypes from '@canvas/files/react/modules/customPropTypes'
import RestrictedDialogForm from '@canvas/files/react/components/RestrictedDialogForm'
import '@canvas/rails-flash-notifications'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import {ltiState} from '@canvas/lti/jquery/messages'

const I18n = useI18nScope('react_files')

export default class Toolbar extends React.Component {
  static propTypes = {
    currentFolder: customPropTypes.folder, // not required as we don't have it on the first render
    contextType: customPropTypes.contextType.isRequired,
    contextId: customPropTypes.contextId.isRequired,
    showingSearchResults: PropTypes.bool,
    usageRightsRequiredForContext: PropTypes.bool,
    userCanAddFilesForContext: PropTypes.bool,
    userCanEditFilesForContext: PropTypes.bool,
    userCanDeleteFilesForContext: PropTypes.bool,
    userCanRestrictFilesForContext: PropTypes.bool,
  }

  UNSAFE_componentWillMount() {
    this.downloadTitle = I18n.t('Download as Zip')
    this.tabIndex = null
  }

  addFolder() {
    return this.props.currentFolder.folders.add({})
  }

  getItemsToDownload() {
    return this.props.selectedItems.filter(item => !item.get('locked_for_user'))
  }

  downloadSelectedAsZip() {
    if (!this.getItemsToDownload().length) return

    return downloadStuffAsAZip(this.getItemsToDownload(), {
      contextType: this.props.contextType,
      contextId: this.props.contextId,
    })
  }

  UNSAFE_componentWillUpdate(nextProps) {
    this.showingButtons = nextProps.selectedItems.length
  }

  // Function Summary
  // Create a blank dialog window via jQuery, then dump the RestrictedDialogForm into that
  // dialog window. This allows us to do react things inside of this already rendered
  // jQueryUI widget
  openRestrictedDialog() {
    const $dialog = $('<div>').dialog({
      title: I18n.t(
        {
          one: 'Edit permissions for: %{itemName}',
          other: 'Edit permissions for %{count} items',
        },
        {
          count: this.props.selectedItems.length,
          itemName: this.props.selectedItems[0].displayName(),
        }
      ),
      width: 800,
      minHeight: 400,
      close() {
        ReactDOM.unmountComponentAtNode(this)
        $(this).remove()
      },
      modal: true,
      zIndex: 1000,
    })

    ReactDOM.render(
      <RestrictedDialogForm
        models={this.props.selectedItems}
        usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
        closeDialog={() => $dialog.dialog('close')}
      />,
      $dialog[0]
    )
  }

  openUsageRightsDialog() {
    const contents = (
      <UsageRightsDialog
        isOpen={true}
        closeModal={this.props.modalOptions.closeModal}
        itemsToManage={this.props.selectedItems}
        userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
      />
    )

    return this.props.modalOptions.openModal(contents, () => this.refs.usageRightsBtn.focus())
  }

  openPreview() {
    FocusStore.setItemToFocus(this.refs.previewLink)
    const queryString = $.param(this.props.getPreviewQuery())
    page(`${this.props.getPreviewRoute()}?${queryString}`)
  }

  onSubmitSearch() {
    const searchTerm = this.refs.searchTerm.value
    page(`/search?search_term=${searchTerm}`)
  }

  renderTrayToolsMenu = () => {
    if (this.props.indexExternalToolsForContext?.length > 0) {
      return (
        <div className="inline-block">
          {/* TODO: use InstUI button */}
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a
            className="al-trigger btn"
            id="file_menu_link"
            role="button"
            tabIndex="0"
            title={I18n.t('Files Menu')}
            aria-label={I18n.t('Files Menu')}
          >
            <i className="icon-more" aria-hidden="true" />
            <span className="screenreader-only">{I18n.t('Files Menu')}</span>
          </a>
          <ul className="al-options" role="menu">
            {this.props.indexExternalToolsForContext.map(tool => (
              <li key={tool.id} role="menuitem">
                {/* TODO: use InstUI button */}
                {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
                <a aria-label={tool.title} href="#" onClick={this.onLaunchTrayTool(tool)}>
                  {this.iconForTrayTool(tool)}
                  {tool.title}
                </a>
              </li>
            ))}
          </ul>
          <div id="external-tool-mount-point" />
        </div>
      )
    }
  }

  iconForTrayTool(tool) {
    if (tool.canvas_icon_class) {
      return <i className={tool.canvas_icon_class} />
    } else if (tool.icon_url) {
      return <img className="icon" alt="" src={tool.icon_url} />
    }
  }

  onLaunchTrayTool = tool => e => {
    if (e != null) {
      e.preventDefault()
    }
    this.setExternalToolTray(tool, document.getElementById('file_menu_link'))
  }

  setExternalToolTray(tool, returnFocusTo) {
    const handleDismiss = () => {
      this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (ltiState?.tray?.refreshOnClose) {
        window.location.reload()
      }
    }
    ReactDOM.render(
      <ContentTypeExternalToolTray
        tool={tool}
        placement="file_index_menu"
        acceptedResourceTypes={['audio', 'document', 'image', 'video']}
        targetResourceType="document" // maybe this isn't what we want but it's my best guess
        allowItemSelection={false}
        selectableItems={[]}
        onDismiss={handleDismiss}
        open={tool !== null}
      />,
      document.getElementById('external-tool-mount-point')
    )
  }

  renderUploadAddFolderButtons(canManage) {
    if (this.props.showingSearchResults) {
      return null
    }
    const phoneHiddenSet = classnames({
      'hidden-phone': this.showingButtons,
    })
    if (canManage) {
      return (
        <div className="ef-actions">
          <button
            type="button"
            onClick={() => this.addFolder()}
            className="btn btn-add-folder"
            aria-label={I18n.t('Add Folder')}
          >
            <i className="icon-plus" />
            &nbsp;
            <span className={phoneHiddenSet}>{I18n.t('Folder')}</span>
          </button>

          <UploadButton
            currentFolder={this.props.currentFolder}
            showingButtons={!!this.showingButtons}
            contextId={this.props.contextId}
            contextType={this.props.contextType}
          />
          {this.renderTrayToolsMenu()}
        </div>
      )
    }
  }

  renderDeleteButton(canManage) {
    if (canManage) {
      return (
        <button
          type="button"
          disabled={!this.showingButtons}
          className="ui-button btn-delete"
          onClick={() => {
            this.props.clearSelectedItems()
            deleteStuff(this.props.selectedItems)
          }}
          title={I18n.t('Delete')}
          aria-label={I18n.t('Delete')}
          data-tooltip=""
        >
          <i className="icon-trash" />
        </button>
      )
    }
  }

  renderManageUsageRightsButton(canManage) {
    if (canManage) {
      return (
        <button
          ref="usageRightsBtn"
          type="button"
          disabled={!this.showingButtons}
          className="Toolbar__ManageUsageRights ui-button btn-rights"
          onClick={() => this.openUsageRightsDialog()}
          title={I18n.t('Manage Usage Rights')}
          aria-label={I18n.t('Manage Usage Rights')}
          data-tooltip=""
        >
          <i className="icon-files-copyright" />
        </button>
      )
    }
  }

  renderCopyCourseButton(canManage) {
    if (canManage) {
      return (
        <button
          type="button"
          disabled={!this.showingButtons}
          className="ui-button btn-move"
          onClick={event => {
            openMoveDialog(this.props.selectedItems, {
              contextType: this.props.contextType,
              contextId: this.props.contextId,
              returnFocusTo: event.target,
              clearSelectedItems: this.props.clearSelectedItems,
              onMove: this.props.onMove,
            })
          }}
          title={I18n.t('Move')}
          aria-label={I18n.t('Move')}
          data-tooltip=""
        >
          <i className="icon-updown" />
        </button>
      )
    }
  }

  renderDownloadButton() {
    if (this.getItemsToDownload().length) {
      if (this.props.selectedItems.length === 1 && this.props.selectedItems[0].get('url')) {
        return (
          <a
            className="ui-button btn-download"
            href={this.props.selectedItems[0].get('url')}
            download={true}
            title={this.downloadTitle}
            aria-label={this.downloadTitle}
            data-tooltip=""
          >
            <i className="icon-download" />
          </a>
        )
      } else {
        return (
          <button
            type="button"
            disabled={!this.showingButtons}
            className="ui-button btn-download"
            onClick={() => this.downloadSelectedAsZip()}
            title={this.downloadTitle}
            aria-label={this.downloadTitle}
            data-tooltip=""
          >
            <i className="icon-download" />
          </button>
        )
      }
    }
  }

  componentDidUpdate(prevProps) {
    if (prevProps.selectedItems.length !== this.props.selectedItems.length) {
      $.screenReaderFlashMessageExclusive(
        I18n.t(
          {one: '%{count} item selected', other: '%{count} items selected'},
          {count: this.props.selectedItems.length}
        )
      )
    }
  }

  renderManageAccessPermissionsButton(canManage) {
    if (canManage) {
      return (
        <button
          type="button"
          disabled={!this.showingButtons}
          className="ui-button btn-restrict"
          onClick={() => this.openRestrictedDialog()}
          title={I18n.t('Manage Access')}
          aria-label={I18n.t('Manage Access')}
          data-tooltip=""
        >
          <i className="icon-cloud-lock" />
        </button>
      )
    }
  }

  render() {
    const selectedItemIsFolder = this.props.selectedItems.every(item => item instanceof Folder)
    let submissionsFolderSelected =
      this.props.currentFolder && this.props.currentFolder.get('for_submissions')
    submissionsFolderSelected =
      submissionsFolderSelected ||
      this.props.selectedItems.some(item => item.get('for_submissions'))
    const restrictedByMasterCourse = this.props.selectedItems.some(
      item => item.get('restricted_by_master_course') && item.get('is_master_course_child_content')
    )
    const {
      userCanRestrictFilesForContext,
      userCanAddFilesForContext,
      userCanEditFilesForContext,
      userCanDeleteFilesForContext,
    } = this.props

    const canManage = permission => {
      return permission && !submissionsFolderSelected && !restrictedByMasterCourse
    }

    this.showingButtons = this.props.selectedItems.length

    if (this.showingButtons === 1) this.downloadTitle = I18n.t('Download')

    const formClassName = classnames({
      'ic-Input-group': true,
      'ef-search-form': true,
      'ef-search-form--showing-buttons': this.showingButtons,
    })

    const buttonSetClasses = classnames({
      'ui-buttonset': true,
      'screenreader-only': !this.showingButtons,
    })

    const viewBtnClasses = classnames({
      'ui-button': true,
      'btn-view': true,
      'Toolbar__ViewBtn--onlyfolders': selectedItemIsFolder,
    })
    const label = selectedItemIsFolder ? I18n.t('Viewing folders is not available') : I18n.t('View')

    return (
      <header className="ef-header" role="region" aria-label={I18n.t('Files Toolbar')}>
        <form className={formClassName} onSubmit={preventDefault(() => this.onSubmitSearch())}>
          <input
            placeholder={I18n.t('Search for files')}
            aria-label={I18n.t('Search for files')}
            type="search"
            ref="searchTerm"
            className="ic-Input"
            defaultValue={this.props.query.search_term}
          />
          <button className="Button" type="submit">
            <i className="icon-search" />
            <span className="screenreader-only">{I18n.t('Search for files')}</span>
          </button>
        </form>

        <div className="ef-header__secondary">
          <div className={buttonSetClasses}>
            {/* TODO: use InstUI button */}
            {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
            <a
              ref="previewLink"
              href="#"
              onClick={!selectedItemIsFolder ? preventDefault(() => this.openPreview()) : () => {}}
              className={viewBtnClasses}
              title={label}
              role="button"
              aria-label={label}
              data-tooltip=""
              disabled={!this.showingButtons || selectedItemIsFolder}
              tabIndex={selectedItemIsFolder ? -1 : 0}
            >
              <i className="icon-eye" />
            </a>

            {this.renderManageAccessPermissionsButton(canManage(userCanRestrictFilesForContext))}
            {this.renderDownloadButton()}
            {this.renderCopyCourseButton(canManage(userCanEditFilesForContext))}
            {this.renderManageUsageRightsButton(
              canManage(userCanEditFilesForContext && this.props.usageRightsRequiredForContext)
            )}
            {this.renderDeleteButton(canManage(userCanDeleteFilesForContext))}
          </div>
          <span className="ef-selected-count hidden-tablet hidden-phone">
            {I18n.t(
              {one: '%{count} item selected', other: '%{count} items selected'},
              {count: this.props.selectedItems.length}
            )}
          </span>
          {this.renderUploadAddFolderButtons(canManage(userCanAddFilesForContext))}
        </div>
      </header>
    )
  }
}
