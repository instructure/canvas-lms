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
import I18n from 'i18n!assignments_2'
import React from 'react'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'

import AvailabilityDates from '../../shared/AvailabilityDates'
import lockedSVG from '../../../../../public/images/assignments_2/Locked.svg'
import {StudentAssignmentShape} from '../assignmentData'

function LockedAssignment(props) {
  const {assignment} = props
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <FlexItem>
        <img alt={I18n.t('Assignment Locked')} src={lockedSVG} />
      </FlexItem>
      <FlexItem>
        <Text size="x-large">{I18n.t('Availability Dates')}</Text>
      </FlexItem>
      <FlexItem>
        <Text size="large">
          <AvailabilityDates assignment={assignment} formatStyle="short" />
        </Text>
      </FlexItem>
    </Flex>
  )
}

LockedAssignment.propTypes = {
  assignment: StudentAssignmentShape
}

export default React.memo(LockedAssignment)
