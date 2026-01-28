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
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {useScope as createI18nScope} from '@canvas/i18n'
import lockExplanation from '@canvas/content-locks/jquery/lock_reason'
import lockedSVG from '@canvas/assignments/react/images/Locked.svg'
import {getPeerReviewUnlockDate} from '../utils/peerReviewLockUtils'
import {Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

const I18n = createI18nScope('peer_reviews_student')

interface LockedPeerReviewProps {
  assignment: Assignment
}

export default function LockedPeerReview({assignment}: LockedPeerReviewProps) {
  const unlockDate = getPeerReviewUnlockDate(assignment)

  return (
    <Flex
      textAlign="center"
      justifyItems="center"
      margin="xx-large 0 0"
      direction="column"
      data-testid="locked-peer-review"
    >
      <Flex.Item>
        <Img alt={I18n.t('Assignment locked until future date')} src={lockedSVG} />
      </Flex.Item>
      <Flex.Item>
        <Flex margin="small" direction="column" alignItems="center">
          <Flex.Item>
            <Heading margin="small">
              {unlockDate
                ? String(lockExplanation({unlock_at: unlockDate}, 'assignment'))
                : I18n.t('Assignment is unavailable.')}
            </Heading>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
