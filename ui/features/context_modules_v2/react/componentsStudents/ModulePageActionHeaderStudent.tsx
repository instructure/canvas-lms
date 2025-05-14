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

const I18n = createI18nScope('context_modules_v2')

interface ModulePageActionHeaderStudentProps {
  courseName?: string
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
}

const ModulePageActionHeaderStudent: React.FC<ModulePageActionHeaderStudentProps> = ({
  courseName,
  onCollapseAll,
  onExpandAll,
  anyModuleExpanded = true,
}) => {
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
    <View as="div" padding="small">
      <View as="div" margin="0 0 medium 0">
        <Heading level="h1">{`${I18n.t('Welcome to ')} ${courseName}!`}</Heading>
      </View>
      <View as="div" margin="0 0 medium 0">
        <Text size="large">
          {I18n.t(
            'Your course content is organized into modules below. Explore each one to learn and complete activities.',
          )}
        </Text>
      </View>
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
}

export default ModulePageActionHeaderStudent
