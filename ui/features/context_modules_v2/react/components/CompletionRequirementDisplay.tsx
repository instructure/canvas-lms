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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CompletionRequirement, ModuleItemContent} from '../utils/types'
import {getItemTypeText} from '../utils/utils'

const I18n = createI18nScope('context_modules_v2')

interface CompletionRequirementDisplayProps {
  completionRequirement: CompletionRequirement
  itemContent: ModuleItemContent
}

const CompletionRequirementDisplay: React.FC<CompletionRequirementDisplayProps> = ({
  completionRequirement,
  itemContent,
}) => {
  if (!completionRequirement) return null

  const {type, minScore, minPercentage, completed = false} = completionRequirement

  const completedText = () => {
    switch (type) {
      case 'min_score':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">
              {I18n.t('Scored at least %{score} points', {score: minScore?.toFixed(1)})}
            </Text>
          </Flex.Item>
        )
      case 'min_percentage':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">
              {I18n.t('Scored at least %{score}%', {score: minPercentage})}
            </Text>
          </Flex.Item>
        )
      case 'must_view':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Viewed')}</Text>
          </Flex.Item>
        )
      case 'must_mark_done':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Marked done')}</Text>
          </Flex.Item>
        )
      case 'must_contribute':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Contributed')}</Text>
          </Flex.Item>
        )
      case 'must_submit':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Submitted')}</Text>
          </Flex.Item>
        )
      default:
        return null
    }
  }

  const incompleteText = () => {
    switch (type) {
      case 'min_score':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">
              {I18n.t('Score at least %{score} points', {score: minScore?.toFixed(1)})}
            </Text>
          </Flex.Item>
        )
      case 'min_percentage':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Score at least %{score}%', {score: minPercentage})}</Text>
          </Flex.Item>
        )
      case 'must_view':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">
              {I18n.t('View %{type}', {type: getItemTypeText(itemContent).toLowerCase()})}
            </Text>
          </Flex.Item>
        )
      case 'must_mark_done':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Mark as done')}</Text>
          </Flex.Item>
        )
      case 'must_contribute':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">{I18n.t('Contribute')}</Text>
          </Flex.Item>
        )
      case 'must_submit':
        return (
          <Flex.Item padding="0">
            <Text size="x-small">
              {I18n.t('Submit %{type}', {type: getItemTypeText(itemContent).toLowerCase()})}
            </Text>
          </Flex.Item>
        )
      default:
        return null
    }
  }

  if (completed) {
    return completedText()
  }

  const txt = incompleteText()

  return txt ? (
    <span>
      <Text weight="bold" size="x-small">
        {I18n.t('To do:')}{' '}
      </Text>
      {txt}
    </span>
  ) : null
}

export default CompletionRequirementDisplay
