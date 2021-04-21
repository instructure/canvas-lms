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

import {Assignment} from '../graphqlData/Assignment'
import AvailabilityDates from '../../shared/AvailabilityDates'
import {bool} from 'prop-types'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!assignments_2_student_header_date_title'
import React from 'react'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'

export default function AssignmentDetails({assignment, isSticky}) {
  return (
    <>
      <Heading margin="0 small medium 0" level="h1" as="h2" data-test-id="title">
        {/* We put 100 here because using auto maxes out at one line and the input for the assignment name never exceeds 100 */}
        <TruncateText maxLines={isSticky ? 1 : 100} truncate={isSticky ? 'character' : 'word'}>
          {assignment.name}
        </TruncateText>
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
        <Text size="large">
          {I18n.t(
            {zero: 'Unlimited Attempts', one: '1 Attempt', other: '%{count} Attempts'},
            {count: assignment.allowedAttempts || 0}
          )}
        </Text>
      </div>
      {!isSticky && (
        <div>
          <Text size="small">
            <AvailabilityDates assignment={assignment} formatStyle="long" />
          </Text>
        </div>
      )}
    </>
  )
}

AssignmentDetails.propTypes = {
  assignment: Assignment.shape,
  isSticky: bool.isRequired
}
