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
import unavailablePeerReviewSVG from '@canvas/assignments/images/UnavailablePeerReview.svg'

const I18n = createI18nScope('peer_reviews_student')

export interface UnavailablePeerReviewProps {
  reason?: string
}

export default function UnavailablePeerReview({reason}: UnavailablePeerReviewProps) {
  const defaultReason = I18n.t(
    'There are no more peer reviews available to allocate to you at this time.',
  )
  const suffix = I18n.t('Check back later or contact your instructor.')
  const message = `${reason || defaultReason} ${suffix}`

  return (
    <Flex
      textAlign="center"
      justifyItems="center"
      data-testid="unavailable-peer-review"
      height="60vh"
    >
      <Flex width="540px" direction="column">
        <Flex.Item>
          <Img
            alt={I18n.t('No peer reviews available')}
            src={unavailablePeerReviewSVG}
            width="120px"
          />
        </Flex.Item>
        <Flex.Item margin="medium 0 0 0">
          <Text size="medium" weight="bold">
            {message}
          </Text>
        </Flex.Item>
      </Flex>
    </Flex>
  )
}
