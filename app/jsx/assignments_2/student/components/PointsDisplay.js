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

function renderPoints(receivedPoints, possiblePoints) {
  let screenReaderPoints, displayPoints
  if (receivedPoints === null || receivedPoints === undefined) {
    screenReaderPoints = I18n.t('Ungraded')
    displayPoints = '-'
  } else {
    screenReaderPoints = receivedPoints
    displayPoints = receivedPoints
  }

  return (
    <div>
      <ScreenReaderContent>
        {`${screenReaderPoints} ${I18n.t('out of')} ${possiblePoints} ${I18n.t('points')}`}
      </ScreenReaderContent>

      <Flex aria-hidden="true" direction="column" textAlign="end">
        <FlexItem>
          <Text size="x-large" data-test-id="points-display">
            {displayPoints}/{possiblePoints}
          </Text>
        </FlexItem>
        <FlexItem>
          <Text>{I18n.t('Points')}</Text>
        </FlexItem>
      </Flex>
    </div>
  )
}

function PointsDisplay(props) {
  const {displayAs, receivedPoints, possiblePoints} = props

  switch (displayAs) {
    case 'points':
      return renderPoints(receivedPoints, possiblePoints)
    default:
      throw new Error(`Invalid displayAs option "${displayAs}"`)
  }
}

// TODO once we add other types here, we can use this to only make possiblePoints
//      required if the displayAs is set to points: https://stackoverflow.com/questions/42299335
//      Would be helpful if the other types are actually passing in different data (A, C+, etc).
PointsDisplay.propTypes = {
  displayAs: PropTypes.string.isRequired,
  receivedPoints: PropTypes.number,
  possiblePoints: PropTypes.number.isRequired
}

PointsDisplay.defaultProps = {
  displayAs: 'points'
}

export default React.memo(PointsDisplay)
