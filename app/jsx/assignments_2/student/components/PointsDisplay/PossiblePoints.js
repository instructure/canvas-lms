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

import I18n from 'i18n!assignments_2_student_points_display'

import PropTypes from 'prop-types'
import React from 'react'

import Text from '@instructure/ui-elements/lib/components/Text'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'

function PossiblePoints(props) {
  const {possiblePoints} = props
  return (
    <div>
      <Flex direction="row" alignItems="end" justifyItems="end" textAlign="end">
        <FlexItem padding="0 x-small">
          <Text size="large" margin="small" data-test-id="points-possible-display">
            {I18n.t('%{possiblePoints} Points Possible', {possiblePoints})}
          </Text>
        </FlexItem>
      </Flex>
    </div>
  )
}

PossiblePoints.propTypes = {
  possiblePoints: PropTypes.number.isRequired
}

export default React.memo(PossiblePoints)
