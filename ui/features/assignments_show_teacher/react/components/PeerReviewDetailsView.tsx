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

import React, {useState} from 'react'
import PeerReviewAllocationRulesTray from '@canvas/assignments/react/PeerReviewAllocationRulesTray'
import {Flex} from '@instructure/ui-flex'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignment_tabs')

export default function PeerReviewDetailsView({
  assignment,
  canEdit,
}: {
  assignment: TeacherAssignmentType
  canEdit: boolean
}) {
  const [showRuleTray, setShowRuleTray] = useState(false)

  return (
    <Flex data-testid="peer-review-details-view">
      <Flex.Item padding="small 0">
        <Link
          data-testid="peer-review-allocation-rules-link"
          variant="standalone"
          href="#"
          onClick={() => setShowRuleTray(true)}
          renderIcon={<IconExternalLinkLine />}
        >
          <Text size="content">{I18n.t('Create Allocation Rules for Peer Reviews')}</Text>
        </Link>
      </Flex.Item>
      <Flex.Item>
        <PeerReviewAllocationRulesTray
          assignmentId={assignment.id}
          requiredPeerReviewsCount={assignment.peerReviews?.count || 1}
          canEdit={canEdit}
          isTrayOpen={showRuleTray}
          closeTray={() => setShowRuleTray(false)}
        />
      </Flex.Item>
    </Flex>
  )
}
