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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ExternalToolModalItem} from '../../utils/types'
import {ContentItem} from '../../hooks/queries/useModuleItemContent'

const I18n = createI18nScope('context_modules_v2')

// Re-export for backward compatibility
export type ExternalTool = ExternalToolModalItem

interface ExternalToolSelectorProps {
  selectedToolId?: string
  onToolSelect: (tool: ExternalToolModalItem | null) => void
  disabled?: boolean
  contentItems: ExternalToolModalItem[]
}

export const ExternalToolSelector: React.FC<ExternalToolSelectorProps> = ({
  selectedToolId,
  onToolSelect,
  disabled = false,
  contentItems,
}) => {
  const availableTools = contentItems

  const selectedTool = useMemo(() => {
    if (!selectedToolId) return null
    return availableTools.find(tool => tool.definition_id === selectedToolId) || null
  }, [availableTools, selectedToolId])

  const handleToolChange = (_event: React.SyntheticEvent, data: {value?: string | number}) => {
    if (!data.value || data.value === '') {
      onToolSelect(null)
      return
    }

    const tool = availableTools.find(t => t.definition_id === data.value?.toString())

    if (tool) {
      onToolSelect(tool)
    }
  }

  if (availableTools.length === 0) {
    return (
      <View as="div" padding="medium" textAlign="center">
        <Text color="secondary">{I18n.t('No external tools are available for this course')}</Text>
      </View>
    )
  }

  return (
    <Flex direction="column" gap="small" margin="0 0 small 0">
      <SimpleSelect
        data-testid="add-item-content-select"
        renderLabel={I18n.t('Select External Tool')}
        assistiveText={I18n.t('Type to search for tools or use arrow keys to navigate options')}
        placeholder={I18n.t('Choose an external tool...')}
        value={selectedTool?.definition_id || ''}
        onChange={handleToolChange}
        disabled={disabled}
      >
        <SimpleSelect.Option id="none" key="none" value="">
          {I18n.t('Select a tool')}
        </SimpleSelect.Option>
        {availableTools
          .sort((a, b) => a.name.localeCompare(b.name))
          .map(tool => (
            <SimpleSelect.Option
              id={
                typeof tool.definition_id === 'number'
                  ? String(tool.definition_id)
                  : tool.definition_id
              }
              key={tool.definition_id}
              value={tool.definition_id}
            >
              {tool.name}
            </SimpleSelect.Option>
          ))}
      </SimpleSelect>

      {selectedTool && (
        <View as="div" padding="small" background="secondary">
          <Flex direction="column" gap="xx-small">
            <Text size="small" weight="bold">
              {I18n.t('Selected Tool: %{name}', {name: selectedTool.name})}
            </Text>
            {selectedTool.description && <Text size="small">{selectedTool.description}</Text>}
            {selectedTool.domain && (
              <Text size="x-small" color="secondary">
                {I18n.t('Domain: %{domain}', {domain: selectedTool.domain})}
              </Text>
            )}
          </Flex>
        </View>
      )}
    </Flex>
  )
}

export default ExternalToolSelector
