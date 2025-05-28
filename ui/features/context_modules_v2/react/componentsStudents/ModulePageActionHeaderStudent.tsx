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
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import ContextModulesHeader from '@canvas/context-modules/react/ContextModulesHeader'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {useCourseStudent} from '../hooks/queriesStudent/useCourseStudent'
import {useContextModule} from '../hooks/useModuleContext'
import {Flex} from '@instructure/ui-flex'
import {IconAssignmentLine, IconWarningLine} from '@instructure/ui-icons'

const I18n = createI18nScope('context_modules_v2')

interface ModulePageActionHeaderStudentProps {
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
}

const ModulePageActionHeaderStudent: React.FC<ModulePageActionHeaderStudentProps> = ({
  onCollapseAll,
  onExpandAll,
  anyModuleExpanded = true,
}) => {
  const {courseId} = useContextModule()
  const {data, isLoading} = useCourseStudent(courseId)

  const handleCollapseExpandClick = useCallback(() => {
    if (anyModuleExpanded) {
      onCollapseAll()
    } else {
      onExpandAll()
    }
  }, [anyModuleExpanded, onCollapseAll, onExpandAll])

  const renderExpandCollapseAll = useCallback(
    (displayOptions?: {
      display: 'block' | 'inline-block' | undefined
      ariaExpanded: boolean
      dataExpand: boolean
      ariaLabel: string
    }) => {
      return (
        <Button
          onClick={handleCollapseExpandClick}
          display={displayOptions?.display}
          aria-expanded={displayOptions?.ariaExpanded}
          data-expand={displayOptions?.dataExpand}
          aria-label={displayOptions?.ariaLabel}
        >
          {anyModuleExpanded ? I18n.t('Collapse All') : I18n.t('Expand All')}
        </Button>
      )
    },
    [anyModuleExpanded, handleCollapseExpandClick],
  )

  return (
    !isLoading && (
      <View as="div">
        {data?.name && (
          <View as="div" margin="0 0 small 0">
            {data?.name ? (
              <Heading level="h1">{`${I18n.t('Welcome to ')} ${data?.name}!`}</Heading>
            ) : (
              <Heading level="h1">{`${I18n.t('Welcome!')}`}</Heading>
            )}
          </View>
        )}
        <View as="div" margin="0 0 medium 0">
          <Text size="large">
            {I18n.t(
              'Your course content is organized into modules below. Explore each one to learn and complete activities.',
            )}
          </Text>
        </View>
        {data?.submissionStatistics?.submissionsDueThisWeekCount ||
        data?.submissionStatistics?.missingSubmissionsCount ? (
          <View as="div" margin="0 0 medium 0">
            <Flex gap="small">
              {data?.submissionStatistics?.submissionsDueThisWeekCount > 0 ? (
                <Flex.Item>
                  <Button
                    data-testid="assignment-due-this-week-button"
                    color="primary"
                    renderIcon={() => <IconAssignmentLine />}
                    withBackground={false}
                    href={`/courses/${courseId}/assignments`}
                  >
                    {I18n.t(
                      {
                        one: '1 Assignment Due This Week',
                        other: '%{count} Assignments Due This Week',
                      },
                      {
                        count: data?.submissionStatistics?.submissionsDueThisWeekCount || 0,
                      },
                    )}
                  </Button>
                </Flex.Item>
              ) : null}
              {data?.submissionStatistics?.missingSubmissionsCount > 0 ? (
                <Flex.Item>
                  <Button
                    data-testid="missing-assignment-button"
                    color="danger"
                    renderIcon={() => <IconWarningLine />}
                    withBackground={false}
                    href={`/courses/${courseId}/assignments`}
                  >
                    {I18n.t(
                      {
                        one: '1 Missing Assignment',
                        other: '%{count} Missing Assignments',
                      },
                      {
                        count: data?.submissionStatistics?.missingSubmissionsCount || 0,
                      },
                    )}
                  </Button>
                </Flex.Item>
              ) : null}
            </Flex>
          </View>
        ) : null}
        {/* @ts-expect-error */}
        {ENV.CONTEXT_MODULES_HEADER_PROPS && (
          <ContextModulesHeader
            // @ts-expect-error
            {...ENV.CONTEXT_MODULES_HEADER_PROPS}
            overrides={{
              expandCollapseAll: {renderComponent: renderExpandCollapseAll},
              hideTitle: true,
            }}
          />
        )}
      </View>
    )
  )
}

export default ModulePageActionHeaderStudent
