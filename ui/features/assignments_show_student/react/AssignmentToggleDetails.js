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

import React from 'react'
import I18n from 'i18n!assignment_2_assignment_toggle_details'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import {string} from 'prop-types'

function AssignmentDetailsText(description) {
  return description
    ? apiUserContent.convert(description)
    : I18n.t('No additional details were added for this assignment.')
}

AssignmentToggleDetails.propTypes = {
  description: string
}

export default function AssignmentToggleDetails(props) {
  return (
    <div className="a2-toggle-details-container">
      <ToggleDetails
        defaultExpanded
        data-test-id="assignments-2-assignment-toggle-details"
        summary={<Text weight="bold">{I18n.t('Details')}</Text>}
      >
        <View margin="0" padding="0">
          {/* html is sanitized on the server side */}
          <div
            className="user_content"
            dangerouslySetInnerHTML={{__html: AssignmentDetailsText(props.description)}}
            data-test-id="assignments-2-assignment-toggle-details-text"
          />
        </View>
      </ToggleDetails>
    </div>
  )
}
