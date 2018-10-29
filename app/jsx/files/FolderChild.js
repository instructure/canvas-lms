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

import I18n from 'i18n!react_files'
import React from 'react'
import createReactClass from 'create-react-class'
import FolderChild from 'compiled/react_files/components/FolderChild'
import filesEnv from 'compiled/react_files/modules/filesEnv'
import classnames from 'classnames'
import ItemCog from '../files/ItemCog'
import PublishCloud from '../shared/PublishCloud'
import MasterCourseLock from '../shared/MasterCourseLock'
import FilesystemObjectThumbnail from '../files/FilesystemObjectThumbnail'
import UsageRightsIndicator from '../files/UsageRightsIndicator'
import Folder from 'compiled/models/Folder'
import preventDefault from 'compiled/fn/preventDefault'
import FriendlyDatetime from '../shared/FriendlyDatetime'
import friendlyBytes from 'compiled/util/friendlyBytes'

FolderChild.isFolder = function() {
  return this.props.model instanceof Folder
}

FolderChild.renderItemCog = function(canManage) {
  if (!this.props.model.isNew() || this.props.model.get('locked_for_user')) {
    return (
      <ItemCog
        model={this.props.model}
        startEditingName={this.startEditingName}
        userCanManageFilesForContext={canManage}
        userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
        usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
        externalToolsForContext={this.props.externalToolsForContext}
        modalOptions={this.props.modalOptions}
        clearSelectedItems={this.props.clearSelectedItems}
        onMove={this.props.onMove}
      />
    )
  }
}
FolderChild.renderPublishCloud = function(canManage) {
  if (!this.props.model.isNew()) {
    return (
      <PublishCloud
        model={this.props.model}
        ref="publishButton"
        userCanManageFilesForContext={canManage}
        usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
      />
    )
  }
}
FolderChild.renderMasterCourseIcon = function(canManage) {
  // never show if not involved in blueprint courses
  if (
    !(
      this.props.model.get('is_master_course_master_content') ||
      this.props.model.get('is_master_course_child_content')
    )
  ) {
    return null
  }
  // Never show the lock on master course folders
  // because we don't always have it's children to know if any are locked
  if (this.isFolder()) {
    if (
      this.props.model.get('is_master_course_master_content') ||
      !this.props.model.get('restricted_by_master_course')
    ) {
      return null
    }
  }

  return <MasterCourseLock model={this.props.model} canManage={canManage} />
}

FolderChild.renderEditingState = function() {
  if (this.state.editing) {
    return (
      <form className="ef-edit-name-form" onSubmit={preventDefault(this.saveNameEdit)}>
        <div className="ic-Input-group">
          <input
            type="text"
            ref="newName"
            className="ic-Input ef-edit-name-form__input"
            placeholder={I18n.t('name', 'Name')}
            aria-label={
              this.isFolder() ? I18n.t('folder_name', 'Folder Name') : I18n.t('File Name')
            }
            defaultValue={this.props.model.displayName()}
            maxLength="255"
            onKeyUp={(event) => {
              if (event.keyCode === 27) {
                this.cancelEditingName()
              }
            }}
          />
          <button
            type="button"
            className="Button ef-edit-name-form__button ef-edit-name-accept"
            onClick={this.saveNameEdit}
          >
            <i className="icon-check" aria-hidden />
            <span className="screenreader-only">{I18n.t('accept', 'Accept')}</span>
          </button>
          <button
            type="button"
            className="Button ef-edit-name-form__button ef-edit-name-cancel"
            onClick={this.cancelEditingName}
          >
            <i className="icon-x" aria-hidden />
            <span className="screenreader-only">{I18n.t('cancel', 'Cancel')}</span>
          </button>
        </div>
      </form>
    )
  } else if (this.isFolder()) {
    return (
      <a
        ref="nameLink"
        href={`${filesEnv.baseUrl}/folder/${this.props.model.urlPath()}`}
        className="ef-name-col__link"
        params={{splat: this.props.model.urlPath()}}
      >
        {/* we use an internal click wrapper span and handle a native js click event so we can
              intercept the link click event before page.js gets it. We want to prevent page.js from
              getting the click event if there is an error and we don't actually want to navigate.
              React's simulated events happen after the native event has been fully dispatched, so
              we can't use react events to intercept the event before page.js processes it. */}
        <span
          className="ef-name-col__click-wrapper"
          ref={elt => {
            if (elt) elt.addEventListener('click', this.checkForAccess)
          }}
        >
          <span className="ef-big-icon-container">
            <FilesystemObjectThumbnail model={this.props.model} />
          </span>
          <span className="ef-name-col__text">{this.props.model.displayName()}</span>
        </span>
      </a>
    )
  } else {
    return (
      <a
        href={this.props.model.get('url')}
        onClick={preventDefault(this.handleFileLinkClick)}
        className="ef-name-col__link"
        ref="nameLink"
      >
        <span className="ef-big-icon-container">
          <FilesystemObjectThumbnail model={this.props.model} />
        </span>
        <span className="ef-name-col__text">{this.props.model.displayName()}</span>
      </a>
    )
  }
}

FolderChild.renderUsageRightsIndicator = function() {
  if (this.props.usageRightsRequiredForContext) {
    return (
      <div className="ef-usage-rights-col" role="gridcell">
        <UsageRightsIndicator
          model={this.props.model}
          userCanManageFilesForContext={this.props.userCanManageFilesForContext}
          userCanRestrictFilesForContext={this.props.userCanRestrictFilesForContext}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          modalOptions={this.props.modalOptions}
        />
      </div>
    )
  }
}

FolderChild.render = function() {
  const user = this.props.model.get('user') || {}
  const selectCheckboxLabel = I18n.t('Select %{itemName}', {itemName: this.props.model.displayName()})
  const keyboardCheckboxClass = classnames({
    'screenreader-only': this.state.hideKeyboardCheck,
    'multiselectable-toggler': true
  })
  const keyboardLabelClass = classnames({
    'screenreader-only': !this.state.hideKeyboardCheck
  })
  const parentFolder = this.props.model.collection && this.props.model.collection.parentFolder
  const canManage =
    this.props.userCanManageFilesForContext &&
    (!parentFolder || !parentFolder.get('for_submissions')) &&
    !this.props.model.get('for_submissions')

  return (
    <div {...this.getAttributesForRootNode()}>
      <label className={keyboardCheckboxClass} role="gridcell">
        <input
          type="checkbox"
          onFocus={() => {
            this.setState({hideKeyboardCheck: false})
          }}
          onBlur={() => {
            this.setState({hideKeyboardCheck: true})
          }}
          className={keyboardCheckboxClass}
          checked={this.props.isSelected}
          onChange={() => {}}
        />
        <span className={keyboardLabelClass}>{selectCheckboxLabel}</span>
      </label>

      <div className="ef-name-col" role="rowheader">
        {this.renderEditingState()}
      </div>

      <div className="ef-date-created-col" role="gridcell">
        <FriendlyDatetime dateTime={this.props.model.get('created_at')} />
      </div>

      <div className="ef-date-modified-col" role="gridcell">
        {!this.isFolder() && <FriendlyDatetime dateTime={this.props.model.get('modified_at')} />}
      </div>

      <div className="ef-modified-by-col ellipsis" role="gridcell">
        <a href={user.html_url} className="ef-plain-link">
          {user.display_name}
        </a>
      </div>

      <div className="ef-size-col" role="gridcell">
        {friendlyBytes(this.props.model.get('size'))}
      </div>

      {this.renderUsageRightsIndicator()}

      <div className="ef-links-col" role="gridcell">
        {this.renderMasterCourseIcon(canManage)}
        {this.renderPublishCloud(canManage && this.props.userCanRestrictFilesForContext)}
        {this.renderItemCog(canManage)}
      </div>
    </div>
  )
}

export default createReactClass(FolderChild)
