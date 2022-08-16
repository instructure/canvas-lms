/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import '@canvas/content-locks/jquery/lock_reason'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'

import unavailablePeerReviewSVG from '../images/UnavailablePeerReview.svg'

const I18n = useI18nScope('assignments_2')

export default function UnavailablePeerReview() {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item margin="medium 0 0 0">
        <img
          alt={I18n.t('There are no submissions available to review just yet.')}
          src={unavailablePeerReviewSVG}
        />
      </Flex.Item>
      <Flex.Item>
        <Flex margin="small" direction="column" alignItems="center" justifyContent="center">
          <Flex.Item>
            <View as="div" margin="0" maxWidth="390px">
              <Heading
                level="h4"
                data-testid="assignments-2-unavailable-pr-label-1"
                margin="xx-small"
              >
                {I18n.t('There are no submissions available to review just yet.')}
              </Heading>
              <Heading
                level="h4"
                data-testid="assignments-2-unavailable-pr-label-2"
                margin="xx-small"
              >
                {I18n.t('Please check back soon.')}
              </Heading>
            </View>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
