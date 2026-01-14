/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'
import {useScope as createI18nScope} from '@canvas/i18n'
import lockExplanation from '@canvas/content-locks/jquery/lock_reason'
import lockedSVG from '@canvas/assignments/react/images/Locked.svg'
import {getPeerReviewUnlockDate, getPeerReviewLockDate} from '../utils/peerReviewLockUtils'
import {Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

interface LockedPeerReviewProps {
  assignment: Assignment
  isPastLockDate?: boolean
}

export default function LockedPeerReview({
  assignment,
  isPastLockDate = false,
}: LockedPeerReviewProps) {
  const unlockDate = getPeerReviewUnlockDate(assignment)
  const lockDate = getPeerReviewLockDate(assignment)

  const getMessage = () => {
    if (isPastLockDate && lockDate) {
      return String(lockExplanation({lock_at: lockDate}, 'peer-review-sub-assignment'))
    }
    if (unlockDate) {
      return String(lockExplanation({unlock_at: unlockDate}, 'assignment'))
    }
    return I18n.t('Assignment is unavailable.')
  }

  return (
    <Flex
      textAlign="center"
      justifyItems="center"
      margin="xx-large 0 0"
      direction="column"
      data-testid="locked-peer-review"
    >
      <Flex.Item>
        <Img alt={I18n.t('Assignment locked until future date')} src={lockedSVG} width="380px" />
      </Flex.Item>
      <Flex.Item>
        <Flex margin="small" direction="column" alignItems="center">
          <Flex.Item margin="small">
            <Text size="medium">{getMessage()}</Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
