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
import {ProgressBar} from '@instructure/ui-progress'
import {filterRequirementsMet} from '../utils/utils'

const I18n = createI18nScope('context_modules_v2')

interface ModuleProgressionStatusBarProps {
  requirementCount?: number
  completionRequirements: CompletionRequirement[]
  progression?: ModuleProgression
}

const ModuleProgressionStatusBar: React.FC<ModuleProgressionStatusBarProps> = ({
  requirementCount,
  completionRequirements,
  progression,
}) => {
  if (!progression || !completionRequirements.length) {
    return null
  }

  const totalCount = requirementCount ? 1 : completionRequirements?.length
  const completedCount =
    filterRequirementsMet(progression.requirementsMet, completionRequirements).length || 0

  const completionPercentage = Math.round((completedCount / totalCount) * 100)
  const isComplete = completionPercentage >= 100
  const completionText = I18n.t('%{completed} of %{total} Required Items', {
    completed: completedCount > totalCount ? totalCount : completedCount,
    total: totalCount,
  })

  return (
    <View as="div" margin="xx-small 0 0 0">
      <Flex alignItems="center">
        <Flex.Item overflowY="hidden" width="33%" margin="xxx-small 0 0 0">
          <View
            as="div"
            width="100%"
            minWidth="100%"
            overflowX="hidden"
            overflowY="hidden"
            borderRadius="large"
            borderColor={isComplete ? 'success' : 'brand'}
            borderWidth="small"
          >
            <ProgressBar
              screenReaderLabel={completionText}
              valueNow={completionPercentage}
              valueMax={100}
              size="small"
              meterColor={isComplete ? 'success' : 'brand'}
              height="0.5rem"
              width="100%"
              themeOverride={{
                borderRadius: 'small',
              }}
            />
          </View>
        </Flex.Item>
        <Flex.Item margin="0 0 0 x-small">
          <Text size="x-small" weight="normal">
            {completionPercentage}%
          </Text>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <Text size="x-small" weight="normal">
            {completionText}
          </Text>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleProgressionStatusBar
