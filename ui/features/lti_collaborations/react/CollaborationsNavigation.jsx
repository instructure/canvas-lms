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
import {useScope as useI18nScope} from '@canvas/i18n'
import NewCollaborationsDropDown from './NewCollaborationsDropDown'

const I18n = useI18nScope('react_collaborations')

class CollaborationsNavigation extends React.Component {
  renderNewCollaborationsDropDown() {
    if (ENV.CREATE_PERMISSION && this.props.ltiCollaborators.ltiCollaboratorsData.length > 0) {
      return (
        <NewCollaborationsDropDown
          ltiCollaborators={this.props.ltiCollaborators.ltiCollaboratorsData}
        />
      )
    }
    return null
  }

  render() {
    return (
      <div className="ic-Action-header">
        <div className="ic-Action-header__Primary">
          <h1 className="screenreader-only">{I18n.t('Collaborations')}</h1>
        </div>
        <div className="ic-Action-header__Secondary">{this.renderNewCollaborationsDropDown()}</div>
      </div>
    )
  }
}

CollaborationsNavigation.propTypes = {
  ltiCollaborators: PropTypes.object.isRequired,
  actions: PropTypes.object,
}

export default CollaborationsNavigation
