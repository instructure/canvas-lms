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

import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import AvailabilityDates from '@canvas/assignments/react/AvailabilityDates'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import lockedSVG from '../../images/Locked.svg'
import React from 'react'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2')

export default function LockedAssignment({assignment}) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item>
        <img alt={I18n.t('Assignment Locked')} src={lockedSVG} />
      </Flex.Item>
      <Flex.Item>
        <Text size="x-large">{I18n.t('Availability Dates')}</Text>
      </Flex.Item>
      <Flex.Item>
        <Text size="large">
          <AvailabilityDates assignment={assignment} formatStyle="short" />
        </Text>
      </Flex.Item>
    </Flex>
  )
}

LockedAssignment.propTypes = {
  assignment: Assignment.shape,
}
