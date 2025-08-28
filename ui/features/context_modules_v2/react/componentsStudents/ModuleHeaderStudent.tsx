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

import React, {useCallback} from 'react'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton, Button} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {
  ModuleProgression,
  CompletionRequirement,
  ModuleStatistics,
  Prerequisite,
} from '../utils/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import ModuleProgressionStatusBar from './ModuleProgressionStatusBar'
import {ModuleHeaderSupplementalInfoStudent} from './ModuleHeaderSupplementalInfoStudent'
import {ModuleHeaderCompletionRequirement} from './ModuleHeaderCompletionRequirement'
import {ModuleHeaderMissingCount} from './ModuleHeaderMissingCount'
import {Pill} from '@instructure/ui-pill'
import ModuleHeaderUnlockAt from '../components/ModuleHeaderUnlockAt'
import {isModuleUnlockAtDateInTheFuture} from '../utils/utils'
import {useContextModule} from '../hooks/useModuleContext'
import {useModules} from '../hooks/queries/useModules'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleHeaderStudentProps {
  id: string
  name: string
  expanded: boolean
  onToggleExpand: (id: string) => void
  progression?: ModuleProgression
  completionRequirements?: CompletionRequirement[]
  prerequisites?: Prerequisite[]
  requirementCount?: number
  unlockAt: string | null
  submissionStatistics?: ModuleStatistics
  smallScreen?: boolean
  showAll?: boolean
  onToggleShowAll?: () => void
}

const ModuleHeaderStudent: React.FC<ModuleHeaderStudentProps> = ({
  id,
  name,
  expanded,
  onToggleExpand,
  progression,
  completionRequirements,
  prerequisites,
  requirementCount,
  unlockAt,
  submissionStatistics,
  smallScreen = false,
  showAll = false,
  onToggleShowAll,
}) => {
  const onToggleExpandRef = useCallback(() => {
    onToggleExpand(id)
  }, [onToggleExpand, id])

  const {courseId, modulesArePaginated, pageSize} = useContextModule()
  const {getModuleItemsTotalCount} = useModules(courseId, 'student')
  const totalCount = getModuleItemsTotalCount(id) || 0
  const missingCount = submissionStatistics?.missingAssignmentCount || 0

  const hasCompletionRequirements = completionRequirements && completionRequirements.length > 0

  const showMissingCount =
    missingCount > 0 && (!progression?.completed || !hasCompletionRequirements)

  const screenReaderLabel = expanded
    ? I18n.t('Collapse "%{name}"', {name})
    : I18n.t('Expand "%{name}"', {name})

  const shouldShowToggle = (totalCount || 0) > pageSize

  return (
    <View as="div" background="transparent">
      <Flex padding="small" justifyItems="space-between" direction="row">
        <Flex.Item shouldGrow shouldShrink margin="0 0 0 small">
          <Flex justifyItems="space-between" direction="column">
            <Flex.Item padding="xxx-small 0 xxx-small 0">
              <Flex
                gap="small"
                alignItems={smallScreen ? 'start' : 'center'}
                justifyItems="end"
                direction={smallScreen ? 'column' : 'row'}
              >
                <Flex.Item shouldShrink>
                  <Heading level="h2">
                    <Text size="large" weight="bold" wrap="break-word">
                      {name}
                    </Text>
                  </Heading>
                </Flex.Item>
                <Flex.Item shouldGrow margin="0 medium 0 0">
                  <Flex justifyItems="end" gap="small" direction={smallScreen ? 'column' : 'row'}>
                    {progression && progression.locked && (
                      <Flex.Item>
                        <Text size="x-small" color="danger">
                          <Pill data-testid="module-header-status-icon-lock">
                            {I18n.t('Locked')}
                          </Pill>
                        </Text>
                      </Flex.Item>
                    )}
                    {showMissingCount && (
                      <Flex.Item>
                        <ModuleHeaderMissingCount submissionStatistics={submissionStatistics} />
                      </Flex.Item>
                    )}
                    {hasCompletionRequirements && (
                      <Flex.Item>
                        <ModuleHeaderCompletionRequirement
                          completed={progression?.completed}
                          requirementCount={requirementCount}
                        />
                      </Flex.Item>
                    )}
                    {expanded && modulesArePaginated && shouldShowToggle && onToggleShowAll && (
                      <Flex.Item>
                        <Button
                          size="small"
                          display="inline-block"
                          onClick={onToggleShowAll}
                          data-testid="show-all-toggle"
                          color="secondary"
                          themeOverride={{
                            borderWidth: '0',
                          }}
                        >
                          {showAll
                            ? I18n.t('Show Less')
                            : I18n.t('Show All (%{count})', {count: totalCount || 0})}
                        </Button>
                      </Flex.Item>
                    )}
                  </Flex>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item overflowX="hidden" overflowY="hidden" margin="small 0 0 0">
              <ModuleHeaderSupplementalInfoStudent submissionStatistics={submissionStatistics} />
            </Flex.Item>
            {completionRequirements?.length && (
              <Flex.Item>
                <ModuleProgressionStatusBar
                  requirementCount={requirementCount}
                  completionRequirements={completionRequirements}
                  progression={progression}
                  smallScreen={smallScreen}
                />
              </Flex.Item>
            )}
            <Flex.Item margin="none">
              <Flex gap="xx-small" alignItems="center" wrap="wrap">
                {unlockAt && isModuleUnlockAtDateInTheFuture(unlockAt) && (
                  <Flex.Item>
                    <ModuleHeaderUnlockAt unlockAt={unlockAt} />
                  </Flex.Item>
                )}
                {unlockAt && isModuleUnlockAtDateInTheFuture(unlockAt) && prerequisites?.length && (
                  <Flex.Item>
                    <Text size="x-small" color="secondary" as="span">
                      |
                    </Text>
                  </Flex.Item>
                )}
                {prerequisites?.length && (
                  <Flex.Item>
                    <Text
                      size="x-small"
                      color="secondary"
                      data-testid="module-header-prerequisites"
                    >
                      {I18n.t(
                        {
                          one: 'Prerequisite: %{prerequisiteName}',
                          other: 'Prerequisites: %{prerequisiteName}',
                        },
                        {
                          count: prerequisites.length,
                          prerequisiteName: prerequisites.map(p => p.name).join(', '),
                        },
                      )}
                    </Text>
                  </Flex.Item>
                )}
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <IconButton
            data-testid="module-header-expand-toggle"
            id={`module-header-expand-toggle-${id}`}
            size="small"
            withBorder={false}
            screenReaderLabel={screenReaderLabel}
            renderIcon={expanded ? IconArrowOpenDownLine : IconArrowOpenUpLine}
            withBackground={false}
            onClick={onToggleExpandRef}
            aria-expanded={expanded}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleHeaderStudent
