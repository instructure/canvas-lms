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

import React, {useState, useEffect, useMemo} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import ExternalToolSelector from './ExternalToolSelector'
import {ContentItem, ModuleItemContentType} from '../../hooks/queries/useModuleItemContent'
import {ExternalToolModalItem} from '../../utils/types'
import {ITEM_TYPE} from '../../utils/constants'
import AddItemFormFieldGroup, {AddItemFormFieldGroupData} from './AddItemFormFieldGroup'

const I18n = createI18nScope('context_modules_v2')

const validateUrl = (url: string, shouldValidateEmpty: boolean = false): string => {
  if (!url.trim()) {
    return shouldValidateEmpty ? I18n.t('URL is required') : ''
  }

  if (!URL.canParse(url)) {
    return I18n.t('Please enter a valid URL')
  }

  return ''
}

interface ExternalItemFormProps extends AddItemFormFieldGroupData {
  onChange: (field: string, value: any) => void
  externalUrlValue?: string
  externalUrlName?: string
  newTab?: boolean
  itemType?: ModuleItemContentType
  contentItems?: ContentItem[]
  formErrors: {name?: string; url?: string}
}

export const ExternalItemForm: React.FC<ExternalItemFormProps> = ({
  onChange,
  externalUrlValue = '',
  externalUrlName = '',
  newTab = false,
  itemType = 'external_url',
  contentItems = [],
  formErrors = {},
  indentValue,
  onIndentChange,
  moduleName,
}: ExternalItemFormProps) => {
  const [url, setUrl] = useState(externalUrlValue)
  const [pageName, setPageName] = useState(externalUrlName)
  const [loadInNewTab, setLoadInNewTab] = useState(newTab)
  const [selectedToolId, setSelectedToolId] = useState<string | undefined>(undefined)
  const [localUrlError, setLocalUrlError] = useState(formErrors.url || '')
  const [hasUserInteracted, setHasUserInteracted] = useState(false)

  const externalToolItems = useMemo(
    () =>
      contentItems.map((item: ContentItem) => ({
        definition_id: item.id,
        definition_type: ITEM_TYPE.EXTERNAL_TOOL,
        name: item.name,
        url: item.url,
        domain: item.domain,
        description: item.description,
        placements: item.placements,
      })) as ExternalToolModalItem[],
    [contentItems],
  )

  // Handle tool selection and auto-populate URL/name
  const handleToolSelect = (tool: ExternalToolModalItem | null) => {
    if (tool) {
      const toolId =
        typeof tool.definition_id === 'number' ? String(tool.definition_id) : tool.definition_id

      setSelectedToolId(toolId)

      // Get the appropriate placement URL and name
      // Try to find any available placement, preferring assignment_selection
      const placement =
        tool?.placements?.assignmentSelection ||
        tool?.placements?.linkSelection ||
        (tool?.placements ? Object.values(tool.placements)[0] : undefined)
      const toolUrl = placement?.url || tool?.url || ''
      const toolTitle = placement?.title || tool?.name || ''

      setUrl(toolUrl)
      setPageName(toolTitle)

      // Notify parent component
      onChange('url', toolUrl)
      onChange('name', toolTitle)
      onChange('selectedToolId', toolId)
    } else {
      setSelectedToolId(undefined)
      onChange('selectedToolId', undefined)
    }
  }

  useEffect(() => {
    // Update parent component when values change
    onChange('url', url)
    onChange('name', pageName)
    onChange('newTab', loadInNewTab)

    const validationError = validateUrl(url, hasUserInteracted)
    setLocalUrlError(validationError)
    onChange('isUrlValid', !validationError && url.trim() !== '')
  }, [url, pageName, loadInNewTab, onChange, hasUserInteracted])

  const isExternalTool = itemType === 'external_tool'

  return (
    <AddItemFormFieldGroup
      indentValue={indentValue}
      onIndentChange={onIndentChange}
      moduleName={moduleName}
    >
      {isExternalTool && (
        <View margin="0 0 medium 0">
          <ExternalToolSelector
            selectedToolId={selectedToolId}
            onToolSelect={handleToolSelect}
            contentItems={externalToolItems}
          />
        </View>
      )}

      <TextInput
        renderLabel={I18n.t('URL')}
        placeholder="https://example.com"
        value={url}
        onChange={(_e, val) => {
          setUrl(val)
          onChange('url', val)
          if (!hasUserInteracted) {
            setHasUserInteracted(true)
          }
        }}
        onBlur={() => {
          if (!hasUserInteracted) {
            setHasUserInteracted(true)
          }
        }}
        margin="0 0 medium 0"
        required
        messages={
          localUrlError || formErrors.url
            ? [{text: localUrlError || formErrors.url, type: 'newError'}]
            : []
        }
      />
      <TextInput
        data-testid="external_item_page_name"
        renderLabel={I18n.t('Page Name')}
        placeholder={I18n.t('Enter page name')}
        value={pageName}
        onChange={(_e, val) => {
          setPageName(val)
          onChange('name', val)
        }}
        margin="0 0 medium 0"
        messages={formErrors.name ? [{text: formErrors.name, type: 'newError'}] : []}
        required
      />
      <Checkbox
        label={I18n.t('Load in a new tab')}
        checked={loadInNewTab}
        onChange={e => {
          setLoadInNewTab(e.target.checked)
          onChange('newTab', e.target.checked)
        }}
        onKeyDown={e => {
          if (e.key === 'Enter') {
            setLoadInNewTab(prev => {
              const newVal = !prev
              onChange('newTab', newVal)
              return newVal
            })
          }
        }}
      />
    </AddItemFormFieldGroup>
  )
}

export default ExternalItemForm
