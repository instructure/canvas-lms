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
import {ModuleItemContent} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemStatusIconProps {
  moduleCompleted: boolean
  content?: ModuleItemContent
}

const ModuleItemStatusIcon: React.FC<ModuleItemStatusIconProps> = ({moduleCompleted, content}) => {
  const isMissing = useMemo(() => {
    if (!content) return false

    return !!content?.submissionsConnection?.nodes?.[0]?.missing
  }, [content])

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
    if (isMissing && !moduleCompleted) {
      return <StatusPill color="danger" text={I18n.t('Missing')} />
    } else if (moduleCompleted) {
      return <StatusPill color="success" text={I18n.t('Complete')} />
    } else {
      return null
    }
  }, [isMissing, moduleCompleted])

  return renderPill ? (
    <View as="div" data-testid="module-item-status-icon">
      {renderPill}
    </View>
  ) : null
}

export default ModuleItemStatusIcon
