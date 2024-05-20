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

import React from 'react'
import createReactClass from 'create-react-class'
import UsageRightsDialog from './LegacyUsageRightsDialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import UsageRightsSelectBox from './UsageRightsSelectBox'
import RestrictedRadioButtons from './RestrictedRadioButtons'
import DialogPreview from './DialogPreview'
import Folder from '../../backbone/models/Folder'
import {Modal} from '@instructure/ui-modal'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import htmlEscape from '@instructure/html-escape'

const I18n = useI18nScope('usage_rights_modal')

const MAX_FOLDERS_TO_SHOW = 2

UsageRightsDialog.renderFileName = function () {
  const textToShow =
    this.props.itemsToManage.length > 1
      ? I18n.t('%{items} items selected', {items: this.props.itemsToManage.length})
      : this.props.itemsToManage[0].displayName()

  return (
    <span ref={e => (this.fileName = e)} className="UsageRightsDialog__fileName">
      {textToShow}
    </span>
  )
}

UsageRightsDialog.renderFolderList = function (folders) {
  if (folders.length) {
    const foldersToShow = folders.slice(0, MAX_FOLDERS_TO_SHOW)
    return (
      <div>
        <span>{I18n.t('Usage rights will be set for all of the files contained in:')}</span>
        <ul ref={e => (this.folderBulletList = e)} className="UsageRightsDialog__folderBulletList">
          {foldersToShow.map(item => (
            <li key={item.cid}>{item.displayName()}</li>
          ))}
        </ul>
      </div>
    )
  } else {
    return null
  }
}

UsageRightsDialog.renderFolderTooltip = function (folders) {
  const toolTipFolders = folders.slice(MAX_FOLDERS_TO_SHOW)

  if (toolTipFolders.length) {
    const renderItems = toolTipFolders.map(item => ({
      cid: item.cid,
      displayName: htmlEscape(item.displayName()).toString(),
    }))
    // Doing it this way so commas, don't show up when rendering the list out in the tooltip.
    const renderedNames = renderItems.map(item => item.displayName).join('<br />')

    return (
      <span
        className="UsageRightsDialog__andMore"
        // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
        tabIndex="0"
        ref={e => (this.folderTooltip = e)}
        data-html-tooltip-title={renderedNames}
        data-tooltip="right"
        data-tooltip-class="UsageRightsDialog__tooltip"
      >
        {I18n.t('and %{count} more…', {count: toolTipFolders.length})}
        <span className="screenreader-only">
          <ul>
            {renderItems.map((item, i) => (
              <li key={item.cid} ref={e => (this[`displayNameTooltip${i}-screenreader`] = e)}>
                {' '}
                {item.displayName}
              </li>
            ))}
          </ul>
        </span>
      </span>
    )
  } else {
    return null
  }
}

UsageRightsDialog.renderFolderMessage = function () {
  const folders = this.props.itemsToManage.filter(item => item instanceof Folder)

  return (
    <div>
      {this.renderFolderList(folders)}
      {this.renderFolderTooltip(folders)}
      <hr aria-hidden="true" />
    </div>
  )
}

UsageRightsDialog.renderDifferentRightsMessage = function () {
  if (
    (this.copyright == null || this.use_justification === 'choose') &&
    this.props.itemsToManage.length > 1
  ) {
    return (
      <span
        ref={e => (this.differentRightsMessage = e)}
        className="UsageRightsDialog__differentRightsMessage alert"
      >
        <i className="icon-warning UsageRightsDialog__warning" />
        {I18n.t('Items selected have different usage rights.')}
      </span>
    )
  }
}

UsageRightsDialog.renderAccessManagement = function () {
  if (this.props.userCanRestrictFilesForContext) {
    return (
      <div>
        <hr aria-hidden="true" />
        <div className="form-horizontal">
          <p className="manage-access">{I18n.t('You can also manage access at this time:')}</p>
          <RestrictedRadioButtons
            ref={e => (this.restrictedSelection = e)}
            models={this.props.itemsToManage}
          />
        </div>
      </div>
    )
  }
}

UsageRightsDialog.render = function () {
  return (
    <Modal
      ref={e => (this.usageRightsDialog = e)}
      open={this.props.isOpen}
      onDismiss={this.props.closeModal}
      label={I18n.t('Manage Usage Rights')}
      shouldCloseOnDocumentClick={false} // otherwise clicking in the datepicker will dismiss the modal underneath it
    >
      <Modal.Header>
        <CloseButton
          elementRef={e => (this.cancelXButton = e)}
          className="Button Button--icon-action"
          placement="end"
          offset="medium"
          onClick={this.props.closeModal}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading level="h4">{I18n.t('Manage Usage Rights')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <div ref={e => (this.form = e)} className="UsageRightsDialog__Content">
          <div>
            <div className="UsageRightsDialog__paddingFix grid-row">
              {!this.props.hidePreview && (
                <div className="UsageRightsDialog__previewColumn col-xs-3">
                  <DialogPreview itemsToShow={this.props.itemsToManage} />
                </div>
              )}
              <div className="UsageRightsDialog__contentColumn off-xs-1 col-xs-8">
                {this.renderDifferentRightsMessage()}
                {this.renderFileName()}
                {this.renderFolderMessage()}
                <UsageRightsSelectBox
                  ref={e => (this.usageSelection = e)}
                  use_justification={this.use_justification}
                  copyright={this.copyright || ''}
                  cc_value={this.cc_value}
                  contextType={this.props.contextType}
                  contextId={this.props.contextId}
                />
                {this.renderAccessManagement()}
              </div>
            </div>
          </div>
        </div>
      </Modal.Body>
      <Modal.Footer>
        <span className="UsageRightsDialog__Footer-Actions">
          <Button elementRef={e => (this.cancelButton = e)} onClick={this.props.closeModal}>
            {I18n.t('Cancel')}
          </Button>
          &nbsp;
          <Button
            elementRef={e => (this.saveButton = e)}
            color="primary"
            type="submit"
            onClick={() => this.submit(this.props.deferSave)}
          >
            {I18n.t('Save')}
          </Button>
        </span>
      </Modal.Footer>
    </Modal>
  )
}

export default createReactClass(UsageRightsDialog)
