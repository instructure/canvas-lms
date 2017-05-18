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
import i18n from 'i18n!react_collaborations'
  class DeleteConfirmation extends React.Component {
    componentDidMount () {
      ReactDOM.findDOMNode(this).focus()
    }

    render () {
      return (
        <div className='DeleteConfirmation' tabIndex='0'>
          <p className='DeleteConfirmation-message'>
            {i18n.t('Remove "%{collaborationTitle}"?', {
              collaborationTitle: this.props.collaboration.title
            })}
          </p>
          <div className='DeleteConfirmation-actions'>
            <button className='Button Button--danger' onClick={this.props.onDelete}>
              {i18n.t('Yes, remove')}
            </button>
            <button className='Button' onClick={this.props.onCancel}>
              {i18n.t('Cancel')}
            </button>
          </div>
        </div>
      )
    }
  };

  DeleteConfirmation.propTypes = {
    collaboration: PropTypes.object,
    onCancel: PropTypes.func,
    onDelete: PropTypes.func
  }

export default DeleteConfirmation
