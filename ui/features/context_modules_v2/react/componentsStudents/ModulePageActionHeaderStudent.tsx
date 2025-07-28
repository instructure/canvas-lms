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
import FeedbackBlock from './FeedbackBlock'

const I18n = createI18nScope('context_modules_v2')

declare const ENV: {
  CONTEXT_MODULES_HEADER_PROPS: any
}

interface ModulePageActionHeaderStudentProps {
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
  disabled?: boolean
}

const ModulePageActionHeaderStudent: React.FC<ModulePageActionHeaderStudentProps> = ({
  onCollapseAll,
  onExpandAll,
  anyModuleExpanded = true,
  disabled = false,
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

  return (
    !isLoading && (
      <View as="div">
        {data?.name && (
          <View as="div" margin="0 0 small 0">
            <Heading level="h1">{`${I18n.t('Welcome to ')} ${data.name}!`}</Heading>
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
            <Flex gap="small" wrap="wrap">
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
        <FeedbackBlock />
        {ENV.CONTEXT_MODULES_HEADER_PROPS && (
          <ContextModulesHeader
            {...ENV.CONTEXT_MODULES_HEADER_PROPS}
            overrides={{
              hideTitle: true,
              expandCollapseAll: {
                onExpandCollapseAll: handleCollapseExpandClick,
                anyModuleExpanded,
                disabled,
              },
            }}
          />
        )}
      </View>
    )
  )
}

export default ModulePageActionHeaderStudent
