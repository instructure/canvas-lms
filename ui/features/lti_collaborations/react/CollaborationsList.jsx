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
import Collaboration from './Collaboration'
import LoadMore from './LoadMore'
import store from './store'

class CollaborationsList extends React.Component {
  loadMoreCollaborations = () => {
    ReactDOM.findDOMNode(
      this.refs[`collaboration-${this.props.collaborationsState.list.length - 1}`]
    ).focus()
    store.dispatch(this.props.getCollaborations(this.props.collaborationsState.nextPage))
  }

  render() {
    return (
      <div className="CollaborationsList">
        <LoadMore
          isLoading={this.props.collaborationsState.listCollaborationsPending}
          hasMore={!!this.props.collaborationsState.nextPage}
          loadMore={this.loadMoreCollaborations}
        >
          {this.props.collaborationsState.list.map((c, index) => (
            <Collaboration
              ref={`collaboration-${index}`}
              key={c.id}
              collaboration={c}
              deleteCollaboration={this.props.deleteCollaboration}
            />
          ))}
        </LoadMore>
      </div>
    )
  }
}

CollaborationsList.propTypes = {
  collaborationsState: PropTypes.object.isRequired,
  deleteCollaboration: PropTypes.func.isRequired,
  getCollaborations: PropTypes.func.isRequired,
}

export default CollaborationsList
