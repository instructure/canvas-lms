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
import I18n from 'i18n!assignment_2'

import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails'

import {string} from 'prop-types'

AssignmentToggleDetails.propTypes = {
  description: string
}

function AssignmentToggleDetails(props) {
  return (
    <ToggleDetails
      data-test-id="assignments-2-assignment-toggle-details"
      summary={<Text weight="bold">{I18n.t('Details')}</Text>}
    >
      <View margin="0" padding="0">
        <Text weight="normal" as="div" data-test-id="assignments-2-assignment-toggle-details-text">
          {props.description}
        </Text>
      </View>
    </ToggleDetails>
  )
}

export default React.memo(AssignmentToggleDetails)
