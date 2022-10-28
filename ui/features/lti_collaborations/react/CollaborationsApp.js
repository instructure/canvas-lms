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
import PropTypes from 'prop-types'
import GettingStartedCollaborations from './GettingStartedCollaborations'
import CollaborationsNavigation from './CollaborationsNavigation'
import CollaborationsList from './CollaborationsList'
import LoadingSpinner from './LoadingSpinner'

// eslint-disable-next-line react/prefer-stateless-function
class CollaborationsApp extends React.Component {
  static propTypes = {
    applicationState: PropTypes.object,
    actions: PropTypes.object,
  }

  render() {
    const {list} = this.props.applicationState.listCollaborations
    const isLoading =
      this.props.applicationState.listCollaborations.listCollaborationsPending ||
      this.props.applicationState.ltiCollaborators.listLTICollaboratorsPending

    return (
      <div className="CollaborationsApp">
        {isLoading ? (
          <LoadingSpinner />
        ) : (
          <div>
            <CollaborationsNavigation
              ltiCollaborators={this.props.applicationState.ltiCollaborators}
            />
            {list.length ? (
              <CollaborationsList
                collaborationsState={this.props.applicationState.listCollaborations}
                getCollaborations={this.props.actions.getCollaborations}
                deleteCollaboration={this.props.actions.deleteCollaboration}
              />
            ) : (
              <GettingStartedCollaborations
                ltiCollaborators={this.props.applicationState.ltiCollaborators}
              />
            )}
          </div>
        )}
      </div>
    )
  }
}

export default CollaborationsApp
