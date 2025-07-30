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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import pandasBalloonUrl from './images/pandasBalloon.svg'

const I18n = createI18nScope('peer_review_allocation_rules_tray')

const EmptyState = () => (
  <Flex
    direction="column"
    alignItems="center"
    justifyItems="center"
    padding="medium"
    textAlign="center"
    margin="large 0 0 0"
  >
    <Img
      src={pandasBalloonUrl}
      alt="Pandas Balloon"
      style={{width: '160px', height: 'auto', marginBottom: '1rem'}}
    />
    <Heading level="h3" margin="medium 0">
      {I18n.t('Create New Rules')}
    </Heading>
    <Text as="p" size="content">
      {I18n.t(
        'Allocation of peer reviews happens behind the scenes and is optimized for a fair distribution to all participants.',
      )}
    </Text>
    <Text as="p" size="content">
      {I18n.t('You can create rules that support your learning goals for the assignment.')}
    </Text>
    <Text size="content">
      {/* TODO: Replace with link to documentation in EGG-1588 */}
      <Link href="#" isWithinText={false} target="_blank">
        {I18n.t('Learn more about how peer review allocation works.')}
      </Link>
    </Text>
  </Flex>
)

const PeerReviewAllocationRulesTray = ({
  courseId,
  assignmentId,
  isTrayOpen,
  closeTray,
}: {
  courseId: string
  assignmentId: string
  isTrayOpen: boolean
  closeTray: () => void
}): React.ReactElement => {
  const trayLabel = I18n.t('Allocation Rules')
  const [rules, setRules] = useState([]) // TODO: Replace with data fetched in EGG-1589

  return (
    <View data-testid="allocation-rules-tray">
      <Tray label={trayLabel} open={isTrayOpen} placement="end">
        <Flex direction="column">
          <Flex.Item>
            <Flex as="div" padding="medium">
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <Heading level="h3" as="h2">
                  {trayLabel}
                </Heading>
              </Flex.Item>

              <Flex.Item>
                <CloseButton
                  data-testid="allocation-rules-tray-close-button"
                  placement="end"
                  offset="medium"
                  screenReaderLabel={I18n.t('Close Allocation Rules Tray')}
                  size="small"
                  onClick={closeTray}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item as="div" padding="xx-small medium x-small medium">
            <Text>
              {I18n.t('For peer review configuration return to ')}
              <Link
                isWithinText={false}
                href={`/courses/${courseId}/assignments/${assignmentId}/edit?scrollTo=assignment_peer_reviews_fields`}
              >
                {I18n.t('Edit Assignment')}
              </Link>
              .
            </Text>
          </Flex.Item>
          <Flex.Item as="div" padding="x-small medium">
            <Button color="primary">{I18n.t('+ Rule')}</Button>
          </Flex.Item>
          {rules.length === 0 && <EmptyState />}
        </Flex>
      </Tray>
    </View>
  )
}

export default PeerReviewAllocationRulesTray
