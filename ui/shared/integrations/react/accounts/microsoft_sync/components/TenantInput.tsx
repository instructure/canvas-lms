/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {TextInput} from '@instructure/ui-text-input'
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('account_settings_jsx_bundle')

interface TenantInputProps {
  tenantInputHandler?: (event: React.ChangeEvent<HTMLInputElement>, value: string) => void
  tenant?: string
  messages?: Array<{
    text: string
    type: 'error' | 'hint' | 'success' | 'screenreader-only'
  }>
}

export default function TenantInput(props: TenantInputProps) {
  return (
    <>
      <TextInput
        renderLabel={<ScreenReaderContent>{I18n.t('Tenant Name Input Area')}</ScreenReaderContent>}
        type="text"
        placeholder={I18n.t('microsoft_tenant_name%{domain}', {domain: '.onmicrosoft.com'})}
        onChange={props.tenantInputHandler}
        defaultValue={props.tenant}
        messages={props.messages}
      />
    </>
  )
}
