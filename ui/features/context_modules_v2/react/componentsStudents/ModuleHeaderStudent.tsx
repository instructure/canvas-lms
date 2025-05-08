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
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import ModuleHeaderStatusIcon from './ModuleHeaderStatusIcon'
import {ModuleProgression, CompletionRequirement} from '../utils/types'
import {useScope as createI18nScope} from '@canvas/i18n'
import ModuleProgressionStatusBar from './ModuleProgressionStatusBar'
import {ModuleHeaderSupplementalInfoStudent} from './ModuleHeaderSupplementalInfoStudent'

const I18n = createI18nScope('context_modules_v2')

interface ModuleHeaderProps {
  id: string
  name: string
  expanded: boolean
  onToggleExpand: (id: string) => void
  progression?: ModuleProgression
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
}

const ModuleHeader: React.FC<ModuleHeaderProps> = ({
  id,
  name,
  expanded,
  onToggleExpand,
  progression,
  completionRequirements,
  requirementCount,
}) => {
  const onToggleExpandRef = useCallback(() => {
    onToggleExpand(id)
  }, [onToggleExpand, id])

  return (
    <View as="div" background="secondary" borderWidth="0 0 small 0" borderRadius="small">
      <Flex padding="small" justifyItems="space-between" direction="row">
        <Flex.Item>
          <IconButton
            size="small"
            withBorder={false}
            screenReaderLabel={expanded ? I18n.t('Collapse module') : I18n.t('Expand module')}
            renderIcon={expanded ? IconArrowOpenUpLine : IconArrowOpenDownLine}
            withBackground={false}
            onClick={onToggleExpandRef}
          />
        </Flex.Item>
        <Flex.Item shouldGrow overflowX="hidden" overflowY="hidden" margin="0 0 0 medium">
          <Flex justifyItems="space-between" direction="column">
            <Flex.Item shouldGrow>
              <Flex gap="small" alignItems="center">
                <Flex.Item>
                  <Heading level="h3">
                    <TruncateText maxLines={1}>{name}</TruncateText>
                  </Heading>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item overflowX="hidden" overflowY="hidden">
              <ModuleHeaderSupplementalInfoStudent
                moduleId={id}
                completionRequirements={completionRequirements || []}
                requirementCount={requirementCount}
                progression={progression}
              />
            </Flex.Item>
            {completionRequirements?.length && (
              <Flex.Item>
                <ModuleProgressionStatusBar
                  completionRequirements={completionRequirements}
                  progression={progression}
                />
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
        <Flex.Item margin="0 0 0 medium">
          {progression && completionRequirements?.length ? (
            <ModuleHeaderStatusIcon progression={progression} />
          ) : null}
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleHeader
