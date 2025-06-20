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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CompletionRequirement} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

interface CompletionRequirementDisplayProps {
  completionRequirement: CompletionRequirement
}

const CompletionRequirementDisplay: React.FC<CompletionRequirementDisplayProps> = ({
  completionRequirement,
}) => {
  if (!completionRequirement) return null

  const {type, minScore, minPercentage, completed = false} = completionRequirement

  switch (type) {
    case 'min_score':
      return (
        <Flex.Item padding="0">
          <Text weight="normal" size="x-small" color={completed ? 'success' : 'primary'}>
            {completed
              ? I18n.t('Scored at least %{score}', {score: minScore?.toFixed(1)})
              : I18n.t('Score at least %{score}', {score: minScore?.toFixed(1)})}
            <ScreenReaderContent>
              {completed
                ? I18n.t('Module item has been completed by scoring at least %{score}', {
                    score: minScore?.toFixed(1),
                  })
                : I18n.t('Must score at least %{score} to complete this module item', {
                    score: minScore?.toFixed(1),
                  })}
            </ScreenReaderContent>
          </Text>
        </Flex.Item>
      )
    case 'min_percentage':
      return (
        <Flex.Item padding="0">
          <Text weight="normal" size="x-small" color={completed ? 'success' : 'primary'}>
            {completed
              ? I18n.t('Scored at least %{score}%', {score: minPercentage})
              : I18n.t('Score at least %{score}%', {score: minPercentage})}
            <ScreenReaderContent>
              {completed
                ? I18n.t('Module item has been completed by scoring at least %{score}%', {
                    score: minPercentage,
                  })
                : I18n.t('Must score at least %{score}% to complete this module item', {
                    score: minPercentage,
                  })}
            </ScreenReaderContent>
          </Text>
        </Flex.Item>
      )
    case 'must_view':
      return (
        <Flex.Item padding="0">
          <Text weight="normal" size="x-small" color={completed ? 'success' : 'primary'}>
            {completed ? I18n.t('Viewed') : I18n.t('View')}
            <ScreenReaderContent>
              {completed
                ? I18n.t('Module item has been viewed and is complete')
                : I18n.t('Must view in order to complete this module item')}
            </ScreenReaderContent>
          </Text>
        </Flex.Item>
      )
    case 'must_mark_done':
      return (
        <Flex.Item padding="0">
          <Text weight="normal" size="x-small" color={completed ? 'success' : 'primary'}>
            {completed ? I18n.t('Marked done') : I18n.t('Mark done')}
            <ScreenReaderContent>
              {completed
                ? I18n.t('Module item marked as done and is complete')
                : I18n.t('Must mark this module item done in order to complete')}
            </ScreenReaderContent>
          </Text>
        </Flex.Item>
      )
    case 'must_contribute':
      return (
        <Flex.Item padding="0">
          <Text weight="normal" size="x-small" color={completed ? 'success' : 'primary'}>
            {completed ? I18n.t('Contributed') : I18n.t('Contribute')}
            <ScreenReaderContent>
              {completed
                ? I18n.t('Contributed to this module item and is complete')
                : I18n.t('Must contribute to this module item to complete it')}
            </ScreenReaderContent>
          </Text>
        </Flex.Item>
      )
    case 'must_submit':
      return (
        <Flex.Item padding="0">
          <Text weight="normal" size="x-small" color={completed ? 'success' : 'primary'}>
            {completed ? I18n.t('Submitted') : I18n.t('Submit')}
            <ScreenReaderContent>
              {completed
                ? I18n.t('Module item submitted and is complete')
                : I18n.t('Must submit this module item to complete it')}
            </ScreenReaderContent>
          </Text>
        </Flex.Item>
      )
    default:
      return null
  }
}

export default CompletionRequirementDisplay
