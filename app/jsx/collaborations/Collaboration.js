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
import DatetimeDisplay from '../shared/DatetimeDisplay'
import DeleteConfirmation from './DeleteConfirmation'
import I18n from 'i18n!react_collaborations'
import splitAssetString from 'compiled/str/splitAssetString'
import store from '../collaborations/store/store'
  class Collaboration extends React.Component {
    constructor (props) {
      super(props);
      this.state = { deleteConfirmationOpen: false };

      this.openConfirmation = this.openConfirmation.bind(this);
      this.closeConfirmation = this.closeConfirmation.bind(this);
      this.deleteCollaboration = this.deleteCollaboration.bind(this);
    }

    openConfirmation () {
      this.setState({
        deleteConfirmationOpen: true
      });
    }

    closeConfirmation () {
      this.setState({
        deleteConfirmationOpen: false
      }, () => {
        ReactDOM.findDOMNode(this.refs.deleteButton).focus()
      });
    }

    deleteCollaboration () {
      let [context, contextId] = splitAssetString(ENV.context_asset_string);
      store.dispatch(this.props.deleteCollaboration(context, contextId, this.props.collaboration.id));
    }

    render () {
      let { collaboration } = this.props;
      let [context, contextId] = splitAssetString(ENV.context_asset_string);
      let editUrl = `/${context}/${contextId}/lti_collaborations/external_tools/retrieve?content_item_id=${collaboration.id}&placement=collaboration&url=${collaboration.update_url}&display=borderless`

      return (
        <div ref="wrapper" className='Collaboration'>
          <div className='Collaboration-body'>
            <a
              className='Collaboration-title'
              href={`/${context}/${contextId}/collaborations/${collaboration.id}`}
              target="_blank"
            >
              {collaboration.title}
            </a>
            <p className='Collaboration-description'>{collaboration.description}</p>
            <a className='Collaboration-author' href={`/users/${collaboration.user_id}`}>{collaboration.user_name},</a>
            <DatetimeDisplay datetime={collaboration.updated_at} format='%b %d, %l:%M %p' />
          </div>
          <div className='Collaboration-actions'>
            {collaboration.permissions.update && (<a className='icon-edit' href={editUrl}>
              <span className='screenreader-only'>{I18n.t('Edit Collaboration')}</span>
            </a>)}

            {collaboration.permissions.delete && (<button ref='deleteButton' className='btn btn-link' onClick={this.openConfirmation}>
                <i className='icon-trash'></i>
                <span className='screenreader-only'>{I18n.t('Delete Collaboration')}</span>
              </button>
            )}
          </div>
          {this.state.deleteConfirmationOpen &&
            <DeleteConfirmation collaboration={collaboration} onCancel={this.closeConfirmation} onDelete={this.deleteCollaboration} />
          }
        </div>
      );
    }
  };

  Collaboration.propTypes = {
    collaboration: PropTypes.object,
    deleteCollaboration: PropTypes.func
  };

export default Collaboration
