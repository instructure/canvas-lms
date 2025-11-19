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
import CreateEditAllocationRuleModal from './CreateEditAllocationRuleModal'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AllocationRuleType} from '../graphql/teacher/AssignmentTeacherTypes'
import {useDeleteAllocationRule} from '../graphql/hooks/useDeleteAllocationRule'
import {formatRuleDescription, formatFullRuleDescription} from './utils/formatRuleDescription'

const I18n = createI18nScope('peer_review_allocation_rule_card')

const AllocationRuleCard = ({
  rule,
  canEdit,
  assignmentId,
  requiredPeerReviewsCount,
  refetchRules,
  handleRuleDelete,
}: {
  rule: AllocationRuleType
  canEdit: boolean
  assignmentId: string
  requiredPeerReviewsCount: number
  refetchRules: (ruleId: string, isNewRule?: boolean, ruleDescription?: string) => void
  handleRuleDelete?: (ruleId: string, ruleDescription?: string, error?: any) => void
}): React.ReactElement => {
  const {mustReview, reviewPermitted, appliesToAssessor, assessor, assessee} = rule
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)

  const {mutate: deleteRule} = useDeleteAllocationRule(
    () => {
      handleRuleDelete?.(rule._id, formatFullRuleDescription(rule))
    },
    error => {
      handleRuleDelete?.(rule._id, undefined, error)
    },
  )

  return (
    <View as="div" padding="xx-small small" borderRadius="medium" borderWidth="small">
      <Flex direction="column">
        <Flex.Item padding="none small" margin="small none xx-small none">
          <Text size="content" wrap="break-word">
            {appliesToAssessor ? assessor.name : assessee.name}{' '}
          </Text>
          <br />
          <Text color="secondary" size="contentSmall" wrap="break-word">
            {formatRuleDescription(rule)}
          </Text>
        </Flex.Item>

        {canEdit && (
          <Flex.Item>
            <Flex>
              <Flex.Item padding="small none x-small small">
                <IconButton
                  id={`edit-rule-button-${rule._id}`}
                  data-testid={`edit-rule-button-${rule._id}`}
                  renderIcon={<IconEditLine color="brand" />}
                  withBackground={false}
                  withBorder={false}
                  size="small"
                  screenReaderLabel={I18n.t('Edit Allocation Rule: %{rule}', {
                    rule: formatFullRuleDescription(rule),
                  })}
                  onClick={() => setIsEditModalOpen(true)}
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
                    rule: formatFullRuleDescription(rule),
                  })}
                  onClick={() => deleteRule({ruleId: rule._id})}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )}
      </Flex>
      <CreateEditAllocationRuleModal
        rule={rule}
        isOpen={isEditModalOpen}
        isEdit={true}
        setIsOpen={setIsEditModalOpen}
        assignmentId={assignmentId}
        requiredPeerReviewsCount={requiredPeerReviewsCount}
        refetchRules={refetchRules}
      />
    </View>
  )
}

export default AllocationRuleCard
