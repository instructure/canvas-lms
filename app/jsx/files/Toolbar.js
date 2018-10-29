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
import I18n from 'i18n!react_files'
import React from 'react'
import ReactDOM from 'react-dom'
import page from 'page'
import FocusStore from 'compiled/react_files/modules/FocusStore'
import openMoveDialog from '../files/utils/openMoveDialog'
import deleteStuff from 'compiled/react_files/utils/deleteStuff'
import UploadButton from '../files/UploadButton'
import classnames from 'classnames'
import preventDefault from 'compiled/fn/preventDefault'
import Folder from 'compiled/models/Folder'
import PropTypes from 'prop-types'
import UsageRightsDialog from './UsageRightsDialog'
import downloadStuffAsAZip from 'compiled/react_files/utils/downloadStuffAsAZip'
import customPropTypes from 'compiled/react_files/modules/customPropTypes'
import RestrictedDialogForm from './RestrictedDialogForm'
import 'compiled/jquery.rails_flash_notifications'

export default class Toolbar extends React.Component {
  static propTypes = {
    currentFolder: customPropTypes.folder, // not required as we don't have it on the first render
    contextType: customPropTypes.contextType.isRequired,
    contextId: customPropTypes.contextId.isRequired,
    showingSearchResults: PropTypes.bool
  }

  componentWillMount() {
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
      contextId: this.props.contextId
    })
  }

  componentWillUpdate(nextProps) {
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
          other: 'Edit permissions for %{count} items'
        },
        {
          count: this.props.selectedItems.length,
          itemName: this.props.selectedItems[0].displayName()
        }
      ),

      width: 800,
      minHeight: 400,
      close() {
        ReactDOM.unmountComponentAtNode(this)
        $(this).remove()
      }
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
        isOpen
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

  renderUploadAddFolderButtons(canManage) {
    if (this.props.showingSearchResults) {
      return null
    }
    const phoneHiddenSet = classnames({
      'hidden-phone': this.showingButtons
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
            <i className="icon-plus" />&nbsp;
            <span className={phoneHiddenSet}>{I18n.t('Folder')}</span>
          </button>

          <UploadButton
            currentFolder={this.props.currentFolder}
            showingButtons={this.showingButtons}
            contextId={this.props.contextId}
            contextType={this.props.contextType}
          />
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
  renderManageUsageRightsButton() {
    if (this.props.userCanManageFilesForContext && this.props.usageRightsRequiredForContext) {
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
              onMove: this.props.onMove
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
            download
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

  renderRestrictedAccessButtons(canManage) {
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
    const canManage =
      this.props.userCanManageFilesForContext &&
      !submissionsFolderSelected &&
      !restrictedByMasterCourse

    this.showingButtons = this.props.selectedItems.length

    if (this.showingButtons === 1) this.downloadTitle = I18n.t('Download')

    const formClassName = classnames({
      'ic-Input-group': true,
      'ef-search-form': true,
      'ef-search-form--showing-buttons': this.showingButtons
    })

    const buttonSetClasses = classnames({
      'ui-buttonset': true,
      'screenreader-only': !this.showingButtons
    })

    const viewBtnClasses = classnames({
      'ui-button': true,
      'btn-view': true,
      'Toolbar__ViewBtn--onlyfolders': selectedItemIsFolder
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
            role="textbox"
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
            <a
              ref="previewLink"
              href="#"
              onClick={!selectedItemIsFolder ? preventDefault(() => this.openPreview()) : (() => {})}
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

            {this.renderRestrictedAccessButtons(
              canManage && this.props.userCanRestrictFilesForContext
            )}
            {this.renderDownloadButton()}
            {this.renderCopyCourseButton(canManage)}
            {this.renderManageUsageRightsButton(canManage)}
            {this.renderDeleteButton(canManage)}
          </div>
          <span className="ef-selected-count hidden-tablet hidden-phone">
            {I18n.t(
              {one: '%{count} item selected', other: '%{count} items selected'},
              {count: this.props.selectedItems.length}
            )}
          </span>
          {this.renderUploadAddFolderButtons(canManage)}
        </div>
      </header>
    )
  }
}
