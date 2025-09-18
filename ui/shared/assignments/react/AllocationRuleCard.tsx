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
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CourseStudent} from '../graphql/hooks/useAssignedStudents'

const I18n = createI18nScope('peer_review_allocation_rule_card')

export type AllocationRuleType = {
  id: string
  reviewer: CourseStudent
  reviewee: CourseStudent
  mustReview: boolean
  reviewPermitted: boolean
  appliesToReviewer: boolean
}

const AllocationRuleCard = ({
  rule,
  canEdit,
}: {
  rule: AllocationRuleType
  canEdit: boolean
}): React.ReactElement => {
  const {mustReview, reviewPermitted, appliesToReviewer, reviewer, reviewee} = rule

  const formatRuleDescription = () => {
    if (appliesToReviewer) {
      if (mustReview && reviewPermitted) {
        return I18n.t('Must review %{subject}', {subject: reviewee.name})
      } else if (mustReview && !reviewPermitted) {
        return I18n.t('Must not review %{subject}', {subject: reviewee.name})
      } else if (!mustReview && reviewPermitted) {
        return I18n.t('Should review %{subject}', {subject: reviewee.name})
      } else {
        return I18n.t('Should not review %{subject}', {subject: reviewee.name})
      }
    } else {
      if (mustReview && reviewPermitted) {
        return I18n.t('Must be reviewed by %{subject}', {subject: reviewer.name})
      } else if (mustReview && !reviewPermitted) {
        return I18n.t('Must not be reviewed by %{subject}', {subject: reviewer.name})
      } else if (!mustReview && reviewPermitted) {
        return I18n.t('Should be reviewed by %{subject}', {subject: reviewer.name})
      } else {
        return I18n.t('Should not be reviewed by %{subject}', {subject: reviewer.name})
      }
    }
  }

  return (
    <View as="div" padding="xx-small small" borderRadius="medium" borderWidth="small">
      <Flex direction="column">
        <Flex.Item padding="none small" margin="small none xx-small none">
          <Text size="content" wrap="break-word">
            {appliesToReviewer ? reviewer.name : reviewee.name}{' '}
          </Text>
          <br />
          <Text color="secondary" size="contentSmall" wrap="break-word">
            {formatRuleDescription()}
          </Text>
        </Flex.Item>

        {canEdit && (
          <Flex.Item>
            <Flex>
              <Flex.Item padding="small none x-small small">
                <IconButton
                  id={`edit-rule-button-${rule.id}`}
                  data-testid={`edit-rule-button-${rule.id}`}
                  renderIcon={<IconEditLine color="brand" />}
                  withBackground={false}
                  withBorder={false}
                  size="small"
                  screenReaderLabel={I18n.t('Edit Allocation Rule: %{rule}', {
                    rule: formatRuleDescription(),
                  })}
                  onClick={() => {}} // TODO [EGG-1627]: Open edit allocation rule modal
                />
              </Flex.Item>
              <Flex.Item padding="small none x-small">
                <IconButton
                  data-testid="delete-allocation-rule-button"
                  renderIcon={<IconTrashLine color="brand" />}
                  withBackground={false}
                  withBorder={false}
                  size="small"
                  screenReaderLabel={I18n.t('Delete Allocation Rule: %{rule}', {
                    rule: formatRuleDescription(),
                  })}
                  onClick={() => {}} // TODO [EGG-1628]: Delete allocation rule
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default AllocationRuleCard
