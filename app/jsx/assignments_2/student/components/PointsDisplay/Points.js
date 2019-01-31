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
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

function PointsDisplayPoints({receivedGrade, possiblePoints}) {
  let screenReaderPoints, displayPoints
  if (receivedGrade === null || receivedGrade === undefined) {
    screenReaderPoints = I18n.t('Ungraded')
    displayPoints = '-'
  } else {
    screenReaderPoints = receivedGrade
    displayPoints = receivedGrade
  }

  return (
    <div>
      <ScreenReaderContent>
        {`${screenReaderPoints} ${I18n.t('out of')} ${possiblePoints} ${I18n.t('points')}`}
      </ScreenReaderContent>

      <Flex aria-hidden="true" direction="column" textAlign="end">
        <FlexItem>
          <Text size="x-large" data-test-id="points-display">
            {displayPoints}/{possiblePoints} {I18n.t('Points')}
          </Text>
        </FlexItem>
      </Flex>
    </div>
  )
}

PointsDisplayPoints.propTypes = {
  receivedGrade: PropTypes.oneOf([PropTypes.number, PropTypes.string]),
  possiblePoints: PropTypes.number.isRequired
}

PointsDisplayPoints.defaultProps = {}

export default React.memo(PointsDisplayPoints)
