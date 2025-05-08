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

import React, {useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CompletionRequirement, ModuleItemContent, ModuleRequirement} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemStatusIconProps {
  itemId: string
  completionRequirement?: CompletionRequirement
  requirementsMet?: ModuleRequirement[]
  content?: ModuleItemContent
}

const ModuleItemStatusIcon: React.FC<ModuleItemStatusIconProps> = ({
  itemId,
  completionRequirement,
  requirementsMet = [],
  content,
}) => {
  const isPastDue = useMemo(() => {
    if (!content) return false

    const dueDate = content.submissionsConnection?.nodes?.[0]?.cachedDueDate
    if (!dueDate) return false

    const now = new Date()
    const dueDateObj = new Date(dueDate)
    return now > dueDateObj
  }, [content])

  const isCompleted = requirementsMet.some(req => req.id.toString() === itemId.toString())

  const StatusPill = ({
    color,
    text,
  }: {
    color: 'primary' | 'success' | 'danger' | 'info'
    text: string
  }) => (
    <Pill color={color}>
      <Flex justifyItems="center">
        <Flex.Item margin="0 0 0 xxx-small">
          <Text size="small">{text}</Text>
        </Flex.Item>
      </Flex>
    </Pill>
  )

  const renderPill = useMemo(() => {
    if (isCompleted) {
      return <StatusPill color="success" text={I18n.t('Complete')} />
    } else if (isPastDue) {
      return <StatusPill color="danger" text={I18n.t('Overdue')} />
    } else if (content?.submissionsConnection?.nodes?.length) {
      return <StatusPill color="info" text={I18n.t('Assigned')} />
    } else {
      return null
    }
  }, [isCompleted, isPastDue, content])

  return renderPill && completionRequirement ? (
    <View as="div" margin="0 0 0 small">
      {renderPill}
    </View>
  ) : null
}

export default ModuleItemStatusIcon
