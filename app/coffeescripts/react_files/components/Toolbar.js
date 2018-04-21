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

import I18n from 'i18n!react_files'
import React from 'react'
import ReactDOM from 'react-dom'
import UsageRightsDialog from 'jsx/files/UsageRightsDialog'
import downloadStuffAsAZip from '../utils/downloadStuffAsAZip'
import customPropTypes from '../modules/customPropTypes'
import RestrictedDialogForm from 'jsx/files/RestrictedDialogForm'
import $ from 'jquery'
import '../../jquery.rails_flash_notifications'

export default {
  displayName: 'Toolbar',

  propTypes: {
    currentFolder: customPropTypes.folder, // not required as we don't have it on the first render
    contextType: customPropTypes.contextType.isRequired,
    contextId: customPropTypes.contextId.isRequired
  },

  componentWillMount() {
    this.downloadTitle = I18n.t('Download as Zip')
    this.tabIndex = null
  },

  addFolder(event) {
    event.preventDefault()
    return this.props.currentFolder.folders.add({})
  },

  getItemsToDownload() {
    return this.props.selectedItems.filter(item => !item.get('locked_for_user'))
  },

  downloadSelectedAsZip() {
    if (!this.getItemsToDownload().length) return

    return downloadStuffAsAZip(this.getItemsToDownload(), {
      contextType: this.props.contextType,
      contextId: this.props.contextId
    })
  },

  componentWillUpdate(nextProps) {
    this.showingButtons = nextProps.selectedItems.length
  },

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
  },

  openUsageRightsDialog(event) {
    event.preventDefault()

    const contents = (
      <UsageRightsDialog
        closeModal={this.props.modalOptions.closeModal}
        itemsToManage={this.props.selectedItems}
        userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
      />
    )

    return this.props.modalOptions.openModal(contents, () =>
      ReactDOM.findDOMNode(this.refs.usageRightsBtn).focus()
    )
  }
}
