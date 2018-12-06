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

import I18n from 'i18n!assignments_2_student_header_date_title'

import React from 'react'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'

import {StudentAssignmentShape} from '../assignmentData'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import AvailabilityDates from '../../shared/AvailabilityDates'

function DateTitle(props) {
  const {assignment} = props

  return (
    <React.Fragment>
      <Heading level="h1" as="h2" data-test-id="title" margin="0 0 x-small">
        {assignment.name}
      </Heading>
      {assignment.dueAt && (
        <Text size="large" data-test-id="due-date-display">
          <FriendlyDatetime
            data-test-id="due-date"
            prefix={I18n.t('Due:')}
            format={I18n.t('#date.formats.full_with_weekday')}
            dateTime={assignment.dueAt}
          />
        </Text>
      )}
      <div>
        <Text size="small">
          <AvailabilityDates assignment={assignment} formatStyle="long" />
        </Text>
      </div>
    </React.Fragment>
  )
}

DateTitle.propTypes = {
  assignment: StudentAssignmentShape
}

export default React.memo(DateTitle)
