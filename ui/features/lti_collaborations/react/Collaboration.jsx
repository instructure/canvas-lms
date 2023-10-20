/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import DatetimeDisplay from '@canvas/datetime/react/components/DatetimeDisplay'
import DeleteConfirmation from './DeleteConfirmation'
import {useScope as useI18nScope} from '@canvas/i18n'
import splitAssetString from '@canvas/util/splitAssetString'
import store from './store'

const I18n = useI18nScope('react_collaborations')

class Collaboration extends React.Component {
  constructor(props) {
    super(props)
    this.state = {deleteConfirmationOpen: false}
  }

  openConfirmation = () => {
    this.setState({
      deleteConfirmationOpen: true,
    })
  }

  closeConfirmation = () => {
    this.setState(
      {
        deleteConfirmationOpen: false,
      },
      () => {
        ReactDOM.findDOMNode(this.deleteButtonRef).focus()
      }
    )
  }

  deleteCollaboration = () => {
    const [context, contextId] = splitAssetString(ENV.context_asset_string)
    store.dispatch(this.props.deleteCollaboration(context, contextId, this.props.collaboration.id))
  }

  render() {
    const {collaboration} = this.props
    const [context, contextId] = splitAssetString(ENV.context_asset_string)
    // until there is an LTI 1.3 Collaborations service for editing, hide the edit button for 1.3 tools.
    // the presence of update_url is a decent signal for a 1.1 collaboration, since the update_url
    // functionality is built into that spec and tools should respect that if they allow editing.
    const canEdit = collaboration.permissions.update && collaboration.update_url
    const editUrl = `/${context}/${contextId}/lti_collaborations/external_tools/retrieve?content_item_id=${collaboration.id}&placement=collaboration&url=${collaboration.update_url}&display=borderless`

    return (
      <div ref="wrapper" className="Collaboration">
        <div className="Collaboration-body">
          <a
            className="Collaboration-title"
            href={`/${context}/${contextId}/collaborations/${collaboration.id}`}
            target="_blank"
            rel="noreferrer"
          >
            {collaboration.title}
          </a>
          <p className="Collaboration-description">{collaboration.description}</p>
          <a className="Collaboration-author" href={`/users/${collaboration.user_id}`}>
            {collaboration.user_name},
          </a>
          <DatetimeDisplay datetime={collaboration.updated_at} format="%b %d, %l:%M %p" />
        </div>
        <div className="Collaboration-actions">
          {canEdit && (
            <a className="icon-edit" href={editUrl}>
              <span className="screenreader-only">{I18n.t('Edit Collaboration')}</span>
            </a>
          )}

          {collaboration.permissions.delete && (
            <button
              type="button"
              ref={c => (this.deleteButtonRef = c)}
              className="btn btn-link"
              onClick={this.openConfirmation}
            >
              <i className="icon-trash" />
              <span className="screenreader-only">{I18n.t('Delete Collaboration')}</span>
            </button>
          )}
        </div>
        {this.state.deleteConfirmationOpen && (
          <DeleteConfirmation
            collaboration={collaboration}
            onCancel={this.closeConfirmation}
            onDelete={this.deleteCollaboration}
          />
        )}
      </div>
    )
  }
}

Collaboration.propTypes = {
  collaboration: PropTypes.object,
  deleteCollaboration: PropTypes.func,
}

export default Collaboration
