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

/* eslint-disable jsx-a11y/anchor-is-valid */

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import preventDefault from '@canvas/util/preventDefault'
import customPropTypes from '@canvas/files/react/modules/customPropTypes'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import File from '@canvas/files/backbone/models/File'
import Folder from '@canvas/files/backbone/models/Folder'
import UsageRightsDialog from '@canvas/files/react/components/UsageRightsDialog'
import openMoveDialog from '../../openMoveDialog'
import downloadStuffAsAZip from '../legacy/util/downloadStuffAsAZip'
import deleteStuff from '../legacy/util/deleteStuff'
import $ from 'jquery'

const I18n = useI18nScope('react_files')

class ItemCog extends React.Component {
  static displayName = 'ItemCog'

  static propTypes = {
    model: customPropTypes.filesystemObject,
    modalOptions: PropTypes.object.isRequired,
    onCopyToClick: PropTypes.func,
    onSendToClick: PropTypes.func,
    externalToolsForContext: PropTypes.arrayOf(PropTypes.object),
    userCanEditFilesForContext: PropTypes.bool,
    userCanDeleteFilesForContext: PropTypes.bool,
    userCanRestrictFilesForContext: PropTypes.bool.isRequired,
    usageRightsRequiredForContext: PropTypes.bool,
  }

  constructor(props) {
    super(props)

    this.settingsCogBtnRef = React.createRef()
  }

  isMasterCourseRestricted = () =>
    this.props.model.get('is_master_course_child_content') &&
    this.props.model.get('restricted_by_master_course')

  downloadFile = (file, args) => {
    window.location = file[0].get('url')
    args.returnFocusTo?.focus()
  }

  downloadZip = (folder, args) => {
    downloadStuffAsAZip(folder, args)
    args.returnFocusTo?.focus()
  }

  deleteItem = (item, args) => {
    // Unfortunately, ars.returnFocusTo isn't really the one we want to focus,
    // because we want the previous one or the +Folder button
    // Also unfortunately, our state management in this app is a bit terrible
    // so we'll just handle all that via jQuery right here for now.
    // TODO: Make this less terrible when we have sane state management
    const allTriggers = $('.al-trigger').toArray()
    const hasMoreTriggers = allTriggers.length - 1 > 0
    let toFocus = document.querySelector('.ef-name-col a')
    if (hasMoreTriggers) {
      const prevTriggerIndex = allTriggers.indexOf(args.returnFocusTo) - 1
      if (prevTriggerIndex >= 0) {
        toFocus = allTriggers[prevTriggerIndex]
      }
    }
    args.returnFocusTo = toFocus
    deleteStuff(item, args)
  }

  openUsageRightsDialog = _event => {
    const contents = (
      <UsageRightsDialog
        isOpen={true}
        closeModal={this.props.modalOptions.closeModal}
        itemsToManage={[this.props.model]}
        userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
      />
    )

    this.props.modalOptions.openModal(contents, () => {
      ReactDOM.findDOMNode(this.settingsCogBtnRef.current).focus()
    })
  }

  render() {
    let externalToolMenuItems
    if (this.props.model instanceof File) {
      externalToolMenuItems = this.props.externalToolsForContext.map(tool => {
        if (this.props.model.externalToolEnabled(tool)) {
          return (
            <li key={tool.title} role="presentation">
              <a
                href={`${tool.base_url}&files[]=${this.props.model.id}`}
                role="menuitem"
                tabIndex="-1"
              >
                {tool.title}
              </a>
            </li>
          )
        } else {
          return (
            <li key={tool.title} role="presentation">
              <a href="#" className="disabled" role="menuitem" tabIndex="-1" aria-disabled="true">
                {tool.title}
              </a>
            </li>
          )
        }
      })
    } else {
      externalToolMenuItems = []
    }

    const wrap = (fn, params = {}) =>
      preventDefault(_event => {
        const singularContextType =
          this.props.model.collection && this.props.model.collection.parentFolder
            ? this.props.model.collection.parentFolder.get('context_type').toLowerCase()
            : null
        const pluralContextType = singularContextType ? `${singularContextType}s` : null
        const contextType = pluralContextType || filesEnv.contextType
        const contextId =
          this.props.model.collection && this.props.model.collection.parentFolder
            ? this.props.model.collection.parentFolder.get('context_id')
            : filesEnv.contextId
        let args = {
          contextType,
          contextId,
          returnFocusTo: ReactDOM.findDOMNode(this.settingsCogBtnRef.current),
        }

        args = $.extend(args, params)
        return fn([this.props.model], args)
      })

    const menuItems = []

    // Download Link
    if (this.props.model instanceof Folder) {
      menuItems.push(
        <li key="folderDownload" role="presentation">
          <a
            href="#"
            onClick={wrap(this.downloadZip)}
            data-testid="download"
            role="menuitem"
            tabIndex="-1"
          >
            {I18n.t('Download')}
          </a>
        </li>
      )
    } else {
      menuItems.push(
        <li key="download" role="presentation">
          <a
            onClick={wrap(this.downloadFile)}
            href={this.props.model.get('url')}
            data-testid="download"
            role="menuitem"
            tabIndex="-1"
          >
            {I18n.t('Download')}
          </a>
        </li>
      )

      if (this.props.userCanEditFilesForContext) {
        if (ENV.context_asset_string?.startsWith('course_')) {
          menuItems.push(
            <li key="send-to" role="presentation">
              <a
                href="#"
                onClick={() => {
                  this.props.onSendToClick(this.props.model)
                }}
                role="menuitem"
                tabIndex="-1"
              >
                {I18n.t('Send To...')}
              </a>
            </li>,

            <li key="copy-to" role="presentation">
              <a
                href="#"
                onClick={() => {
                  this.props.onCopyToClick(this.props.model)
                }}
                role="menuitem"
                tabIndex="-1"
              >
                {I18n.t('Copy To...')}
              </a>
            </li>
          )
        }
      }
    }

    if (!this.isMasterCourseRestricted()) {
      if (this.props.userCanEditFilesForContext) {
        // Rename Link
        menuItems.push(
          <li key="rename" role="presentation">
            <a
              href="#"
              onClick={preventDefault(this.props.startEditingName)}
              data-testid="editName"
              role="menuitem"
              tabIndex="-1"
            >
              {I18n.t('Rename')}
            </a>
          </li>
        )
        // Move Link
        menuItems.push(
          <li key="move-to" role="presentation">
            <a
              href="#"
              onClick={wrap(openMoveDialog, {
                clearSelectedItems: this.props.clearSelectedItems,
                onMove: this.props.onMove,
              })}
              data-testid="move"
              role="menuitem"
              tabIndex="-1"
            >
              {I18n.t('Move To...')}
            </a>
          </li>
        )
        // Manage Usage Rights Link
        if (this.props.usageRightsRequiredForContext) {
          menuItems.push(
            <li key="manageUsageRights" className="ItemCog__OpenUsageRights" role="presentation">
              <a
                href="#"
                onClick={preventDefault(this.openUsageRightsDialog)}
                data-testid="usageRights"
                role="menuitem"
                tabIndex="-1"
              >
                {I18n.t('Manage Usage Rights')}
              </a>
            </li>
          )
        }
      }

      if (this.props.userCanDeleteFilesForContext) {
        // Delete Link
        menuItems.push(
          <li key="delete" role="presentation">
            <a
              href="#"
              onClick={wrap(this.deleteItem)}
              data-testid="deleteLink"
              role="menuitem"
              tabIndex="-1"
            >
              {I18n.t('Delete')}
            </a>
          </li>
        )
      }
    }

    return (
      // without the stopPropagation(), using the cog menu causes the file's invisible selection checkbox to be toggled as well
      // eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions
      <div
        className="al-dropdown__container"
        style={{minWidth: '45px', display: 'inline-block'}}
        onClick={e => e.stopPropagation()}
      >
        <button
          type="button"
          ref={this.settingsCogBtnRef}
          data-testid="settingsCogBtn"
          className="al-trigger al-trigger-gray btn btn-link"
          aria-label={I18n.t('Actions')}
          data-popup-within="#application"
          data-append-to-body={true}
        >
          <i className="icon-more" />
        </button>
        {/* eslint-disable-next-line jsx-a11y/role-supports-aria-props */}
        <ul
          className="al-options"
          role="menu"
          aria-hidden="true"
          aria-expanded="false"
          tabIndex="0"
        >
          {menuItems.concat(externalToolMenuItems)}
        </ul>
      </div>
    )
  }
}

export default ItemCog
