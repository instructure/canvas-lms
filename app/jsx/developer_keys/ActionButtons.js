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

import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import IconEditLine from '@instructure/ui-icons/lib/Line/IconEdit'
import IconEyeLine from '@instructure/ui-icons/lib/Line/IconEye'
import IconOffLine from '@instructure/ui-icons/lib/Line/IconOff'
import IconTrashLine from '@instructure/ui-icons/lib/Line/IconTrash'

class DeveloperKeyActionButtons extends React.Component {
  makeVisibleLinkHandler = (event) => {
    const { dispatch, makeVisibleDeveloperKey, developerKey } = this.props
    event.preventDefault()
    dispatch(makeVisibleDeveloperKey(developerKey))
  }

  makeInvisibleLinkHandler = (event) => {
    const { dispatch, makeInvisibleDeveloperKey, developerKey } = this.props
    event.preventDefault()
    dispatch(makeInvisibleDeveloperKey(developerKey))
  }

  deleteLinkHandler = (event) => {
    const { dispatch, deleteDeveloperKey, developerKey, onDelete } = this.props
    event.preventDefault()
    const confirmResult = confirm(this.confirmationMessage(developerKey))
    if (confirmResult) {
      const callBack = onDelete()
      deleteDeveloperKey(developerKey)(dispatch)
        .then(() => { callBack() })
    }
  }

  editLinkHandler = (event) => {
    const { dispatch, editDeveloperKey, developerKeysModalOpen, developerKey, ltiKeysSetLtiKey, developerKey: {is_lti_key} } = this.props

    event.preventDefault()
    if (is_lti_key) { dispatch(ltiKeysSetLtiKey(true)) }
    dispatch(editDeveloperKey(developerKey))
    dispatch(developerKeysModalOpen(is_lti_key ? 'lti' : 'api'))
  }

  focusDeleteLink = () => { this.deleteLink.focus() }

  refDeleteLink = (link) => { this.deleteLink = link; }

  confirmationMessage(developerKey) {
    if (developerKey.is_lti_key) {
      return I18n.t(
        "Are you sure you want to delete this developer key? This action will also delete all tools associated with the developer key in this context."
      )
    }
    return I18n.t('Are you sure you want to delete this developer key?')
  }

  renderVisibilityIcon () {
    const { developerName, visible, showVisibilityToggle } = this.props
    if (!showVisibilityToggle) { return null }
    if (visible) {
      return <Tooltip
        tip={I18n.t("Make key invisible")}
      >
        <Button
          variant="icon"
          margin="0"
          size="small"
          onClick={this.makeInvisibleLinkHandler}
        >
          <ScreenReaderContent>{I18n.t('Make key %{developerName} invisible', {developerName})}</ScreenReaderContent>
          <IconEyeLine />
        </Button>
      </Tooltip>
    }

    return <Tooltip
      tip={I18n.t("Make key visible")}
    >
      <Button
        variant="icon"
        margin="0"
        size="small"
        onClick={this.makeVisibleLinkHandler}
      >
        <ScreenReaderContent>{I18n.t('Make key %{developerName} visible', {developerName})}</ScreenReaderContent>
        <IconOffLine />
      </Button>
    </Tooltip>
  }

  renderEditButton () {
    const { developerName } = this.props;

    return (
      <Tooltip
          tip={I18n.t("Edit this key")}
        >
        <Button
          variant="icon"
          margin="0"
          size="small"
          onClick={this.editLinkHandler}
        >
          <ScreenReaderContent>{I18n.t("Edit key %{developerName}", {developerName})}</ScreenReaderContent>
          <IconEditLine />
        </Button>
      </Tooltip>
    )
  }

  render () {
    const { developerName } = this.props;

    return (
      <div>
        {this.renderEditButton()}
        {this.renderVisibilityIcon()}
        <Tooltip
          tip={I18n.t("Delete this key")}
        >
          <Button
            variant="icon"
            margin="0"
            size="small"
            onClick={this.deleteLinkHandler}
            buttonRef={this.refDeleteLink}
          >
            <ScreenReaderContent>{I18n.t("Delete key %{developerName}", {developerName})}</ScreenReaderContent>
            <IconTrashLine />
          </Button>
        </Tooltip>
      </div>
    );
  };
}

DeveloperKeyActionButtons.propTypes = {
  dispatch: PropTypes.func.isRequired,
  makeVisibleDeveloperKey: PropTypes.func.isRequired,
  makeInvisibleDeveloperKey: PropTypes.func.isRequired,
  deleteDeveloperKey: PropTypes.func.isRequired,
  editDeveloperKey: PropTypes.func.isRequired,
  developerKeysModalOpen: PropTypes.func.isRequired,
  ltiKeysSetLtiKey: PropTypes.func.isRequired,
  developerKey: PropTypes.shape({
    id: PropTypes.string.isRequired,
    api_key: PropTypes.string,
    created_at: PropTypes.string.isRequired,
    is_lti_key: PropTypes.bool
  }).isRequired,
  visible: PropTypes.bool.isRequired,
  developerName: PropTypes.string.isRequired,
  onDelete: PropTypes.func.isRequired,
  showVisibilityToggle: PropTypes.bool
};

DeveloperKeyActionButtons.defaultProps = {
  showVisibilityToggle: true
}

export default DeveloperKeyActionButtons
