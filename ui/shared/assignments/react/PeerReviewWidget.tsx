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

import React, {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {IconPeerReviewLine, IconSettingsLine} from '@instructure/ui-icons'
import {PeerReviewConfigurationTray} from './PeerReviewConfigurationTray'
import PeerReviewAllocationRulesTray from './PeerReviewAllocationRulesTray'

const I18n = createI18nScope('peer-review-assignment-widget')

export interface PeerReviewWidgetProps {
  assignmentId: string
  courseId: string
}

export const PeerReviewWidget = ({assignmentId, courseId}: PeerReviewWidgetProps) => {
  const [isConfigTrayOpen, setIsConfigTrayOpen] = useState(false)
  const [isAllocationTrayOpen, setIsAllocationTrayOpen] = useState(false)

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    if (params.get('open_allocation_tray') === 'true') {
      setIsAllocationTrayOpen(true)
    }
  }, [])

  return (
    <>
      <View
        as="div"
        display="inline-block"
        borderColor="primary"
        borderWidth="small"
        padding="small"
      >
        <View>
          <IconPeerReviewLine />
          <View as="div" margin="0 0 0 small" display="inline-block">
            <Text>{I18n.t('Peer Review')}</Text>
          </View>

          <Button
            margin="0 0 0 x-large"
            renderIcon={<IconSettingsLine />}
            data-testid="view-configuration-button"
            aria-label={I18n.t('View Peer Review Configuration')}
            onClick={() => setIsConfigTrayOpen(true)}
          >
            {I18n.t('View Configuration')}
          </Button>
          <Button
            margin="0 0 0 small"
            data-testid="allocate-peer-reviews-button"
            aria-label={I18n.t('Open Peer Review Allocation Tray')}
            onClick={() => setIsAllocationTrayOpen(true)}
          >
            {I18n.t('Allocate Peer Reviews')}
          </Button>
        </View>
      </View>
      <PeerReviewConfigurationTray
        assignmentId={assignmentId}
        isTrayOpen={isConfigTrayOpen}
        closeTray={() => setIsConfigTrayOpen(false)}
      />
      <PeerReviewAllocationRulesTray
        assignmentId={assignmentId}
        isTrayOpen={isAllocationTrayOpen}
        closeTray={() => setIsAllocationTrayOpen(false)}
        canEdit={ENV.CAN_EDIT_ASSIGNMENTS || false}
      />
    </>
  )
}
