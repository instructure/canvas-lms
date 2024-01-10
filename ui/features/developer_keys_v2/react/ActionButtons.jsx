/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import page from 'page'

import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconEditLine, IconEyeLine, IconOffLine, IconTrashLine} from '@instructure/ui-icons'

const I18n = useI18nScope('react_developer_keys')

class DeveloperKeyActionButtons extends React.Component {
  makeVisibleLinkHandler = event => {
    const {dispatch, makeVisibleDeveloperKey, developerKey} = this.props
    event.preventDefault()
    dispatch(makeVisibleDeveloperKey(developerKey))
  }

  makeInvisibleLinkHandler = event => {
    const {dispatch, makeInvisibleDeveloperKey, developerKey} = this.props
    event.preventDefault()
    dispatch(makeInvisibleDeveloperKey(developerKey))
  }

  deleteLinkHandler = event => {
    const {dispatch, deleteDeveloperKey, developerKey, onDelete} = this.props
    event.preventDefault()
    const confirmResult = window.confirm(this.confirmationMessage(developerKey))
    if (confirmResult) {
      onDelete(developerKey.id)
      dispatch(deleteDeveloperKey(developerKey))
    }
  }

  editLinkHandler = event => {
    const {
      dispatch,
      editDeveloperKey,
      developerKeysModalOpen,
      developerKey,
      ltiKeysSetLtiKey,
      developerKey: {is_lti_key},
    } = this.props

    event.preventDefault()
    if (is_lti_key) {
      dispatch(ltiKeysSetLtiKey(true))
    }
    dispatch(editDeveloperKey(developerKey))
    dispatch(developerKeysModalOpen(is_lti_key ? 'lti' : 'api'))
  }

  focusDeleteLink = () => {
    this.deleteLink.focus()
  }

  refDeleteLink = link => {
    this.deleteLink = link
  }

  confirmationMessage(developerKey) {
    if (developerKey.is_lti_key) {
      return I18n.t(
        'Are you sure you want to delete this developer key? This action will also delete all tools associated with the developer key in this context.'
      )
    }
    return I18n.t('Are you sure you want to delete this developer key?')
  }

  renderVisibilityIcon() {
    const {developerName, visible, showVisibilityToggle} = this.props
    if (!showVisibilityToggle) {
      return null
    }
    if (visible) {
      return (
        <Tooltip renderTip={I18n.t('Make key invisible')}>
          <IconButton
            withBackground={false}
            withBorder={false}
            margin="0"
            size="small"
            onClick={this.makeInvisibleLinkHandler}
            screenReaderLabel={I18n.t('Make key %{developerName} invisible', {developerName})}
          >
            <IconEyeLine />
          </IconButton>
        </Tooltip>
      )
    }

    return (
      <Tooltip renderTip={I18n.t('Make key visible')}>
        <IconButton
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Make key %{developerName} visible', {developerName})}
          margin="0"
          size="small"
          onClick={this.makeVisibleLinkHandler}
        >
          <IconOffLine />
        </IconButton>
      </Tooltip>
    )
  }

  renderEditButton() {
    const {developerName, developerKey} = this.props

    return developerKey.is_lti_registration ? (
      <Tooltip renderTip={I18n.t('Edit this key')}>
        <IconButton
          id="edit-developer-key-button"
          as={'a'}
          href={`/accounts/${this.props.contextId}/developer_keys/${developerKey.id}`}
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Edit key %{developerName}', {developerName})}
          margin="0"
          size="small"
        >
          <IconEditLine />
        </IconButton>
      </Tooltip>
    ) : (
      <Tooltip renderTip={I18n.t('Edit this key')}>
        <IconButton
          id="edit-developer-key-button"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Edit key %{developerName}', {developerName})}
          margin="0"
          size="small"
          onClick={this.editLinkHandler}
        >
          <IconEditLine />
        </IconButton>
      </Tooltip>
    )
  }

  render() {
    const {developerName} = this.props

    return (
      <div>
        {this.renderEditButton()}
        {this.renderVisibilityIcon()}
        <Tooltip renderTip={I18n.t('Delete this key')}>
          <IconButton
            id="delete-developer-key-button"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Delete key %{developerName}', {developerName})}
            margin="0"
            size="small"
            onClick={this.deleteLinkHandler}
            elementRef={this.refDeleteLink}
          >
            <IconTrashLine />
          </IconButton>
        </Tooltip>
      </div>
    )
  }
}

DeveloperKeyActionButtons.propTypes = {
  dispatch: PropTypes.func.isRequired,
  makeVisibleDeveloperKey: PropTypes.func.isRequired,
  makeInvisibleDeveloperKey: PropTypes.func.isRequired,
  deleteDeveloperKey: PropTypes.func.isRequired,
  editDeveloperKey: PropTypes.func.isRequired,
  developerKeysModalOpen: PropTypes.func.isRequired,
  ltiKeysSetLtiKey: PropTypes.func.isRequired,
  contextId: PropTypes.string.isRequired,
  developerKey: PropTypes.shape({
    id: PropTypes.string.isRequired,
    api_key: PropTypes.string,
    created_at: PropTypes.string.isRequired,
    is_lti_key: PropTypes.bool,
  }).isRequired,
  visible: PropTypes.bool.isRequired,
  developerName: PropTypes.string.isRequired,
  onDelete: PropTypes.func.isRequired,
  showVisibilityToggle: PropTypes.bool,
}

DeveloperKeyActionButtons.defaultProps = {
  showVisibilityToggle: true,
}

export default DeveloperKeyActionButtons
