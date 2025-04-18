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

import React, {useState, useEffect} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

// Types for props
interface ExternalItemFormProps {
  onChange: (field: string, value: any) => void
  externalUrlValue?: string
  externalUrlName?: string
  newTab?: boolean
}

export const ExternalItemForm: React.FC<ExternalItemFormProps> = ({
  onChange,
  externalUrlValue = '',
  externalUrlName = '',
  newTab = false,
}) => {
  const [url, setUrl] = useState(externalUrlValue)
  const [pageName, setPageName] = useState(externalUrlName)
  const [loadInNewTab, setLoadInNewTab] = useState(newTab)

  useEffect(() => {
    // Update parent component when values change
    onChange('url', url)
    onChange('name', pageName)
    onChange('newTab', loadInNewTab)
  }, [url, pageName, loadInNewTab, onChange])

  return (
    <View as="form" padding="small" display="block">
      <TextInput
        renderLabel={I18n.t('URL')}
        placeholder="https://example.com"
        value={url}
        onChange={(_e, val) => {
          setUrl(val)
          onChange('url', val)
        }}
        margin="0 0 medium 0"
        required
      />
      <TextInput
        renderLabel={I18n.t('Page Name')}
        placeholder={I18n.t('Enter page name')}
        value={pageName}
        onChange={(_e, val) => {
          setPageName(val)
          onChange('name', val)
        }}
        margin="0 0 medium 0"
        required
      />
      <Checkbox
        label={I18n.t('Load in a new tab')}
        checked={loadInNewTab}
        onChange={e => {
          setLoadInNewTab(e.target.checked)
          onChange('newTab', e.target.checked)
        }}
      />
    </View>
  )
}

export default ExternalItemForm
