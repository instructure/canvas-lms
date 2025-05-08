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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {CompletionRequirement, ModuleProgression} from '../utils/types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

interface ModuleProgressionStatusBarProps {
  completionRequirements: CompletionRequirement[]
  progression?: ModuleProgression
}

const ModuleProgressionStatusBar: React.FC<ModuleProgressionStatusBarProps> = ({
  completionRequirements,
  progression,
}) => {
  if (!progression || !completionRequirements.length) {
    return null
  }

  const completedCount = progression.requirementsMet?.length || 0
  const totalCount = completionRequirements.length

  const completionPercentage = Math.round((completedCount / totalCount) * 100)
  const isComplete = completionPercentage === 100
  const completionText = I18n.t('%{completed}/%{total} Required Items Completed', {
    completed: completedCount,
    total: totalCount,
  })

  return (
    <View as="div" margin="small 0 0 0">
      <Flex direction="column" gap="x-small">
        <Flex.Item>
          <View
            as="div"
            background="primary"
            borderWidth="small"
            borderRadius="medium"
            width="70%"
            height="0.5rem"
            themeOverride={{
              backgroundPrimary: 'white',
            }}
          >
            <View
              as="div"
              background={isComplete ? 'success' : 'brand'}
              borderRadius="medium"
              width={`${completionPercentage}%`}
              height="100%"
            />
          </View>
        </Flex.Item>
        <Flex.Item>
          <Text size="small" weight="normal">
            {completionText}
          </Text>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleProgressionStatusBar
