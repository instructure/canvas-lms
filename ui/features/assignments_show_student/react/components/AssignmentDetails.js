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
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2_student_header_date_title')

export default function AssignmentDetails({assignment}) {
  return (
    <>
      <Heading margin="0" as="h2" data-test-id="title" theme={{h2FontWeight: 300}}>
        <TruncateText maxLines={1} truncate="character">
          {assignment.name}
        </TruncateText>
      </Heading>
      {(assignment.env.peerReviewModeEnabled || assignment.dueAt) && (
        <Text size="small" weight="bold" data-testid="assignment-sub-header">
          {assignment.env.peerReviewModeEnabled &&
            `${I18n.t('Peer:')} ${assignment.env.peerDisplayName}`}
          {assignment.dueAt && (
            <>
              {assignment.env.peerReviewModeEnabled && ' | '}
              <FriendlyDatetime
                data-test-id="due-date"
                prefix={I18n.t('Due:')}
                format={I18n.t('#date.formats.full_with_weekday')}
                dateTime={assignment.dueAt}
              />
            </>
          )}
        </Text>
      )}
    </>
  )
}

AssignmentDetails.propTypes = {
  assignment: Assignment.shape,
}
