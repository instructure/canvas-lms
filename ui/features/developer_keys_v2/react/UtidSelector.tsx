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

import React, {useEffect} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {useUtidMatching, type ApiRegistration} from '../hooks/useUtidMatching'
import type {FormMessageChild, FormMessageType} from '@instructure/ui-form-field/src/FormPropTypes'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconInfoLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('react_developer_keys')

interface UtidSelectorProps {
  redirectUris: string | undefined
  accountId: string
  selectedUtid: string | null | undefined
  onUtidChange: (utid: string | null) => void
  showRequiredMessage: boolean
  onValidationChange?: (isValid: boolean) => void
}

export const UtidSelector: React.FC<UtidSelectorProps> = ({
  redirectUris,
  accountId,
  selectedUtid,
  onUtidChange,
  showRequiredMessage,
  onValidationChange,
}) => {
  const {matches, loading, error} = useUtidMatching(redirectUris, accountId)

  useEffect(() => {
    if (matches.length === 1 && !selectedUtid) {
      onUtidChange(matches[0].unified_tool_id)
    }
    if (matches.length === 0 && selectedUtid) {
      onUtidChange(null)
    }
  }, [matches, selectedUtid, onUtidChange])

  const hasMatches = matches.length > 0
  const hasSelection = Boolean(selectedUtid)
  const isRequired = hasMatches && !hasSelection
  const isValid = !hasMatches || hasSelection

  useEffect(() => {
    if (onValidationChange) {
      onValidationChange(isValid)
    }
  }, [isValid, onValidationChange])

  const showError = showRequiredMessage && !isValid

  const validationMessages: {text: FormMessageChild; type: FormMessageType}[] = showError
    ? [
        {
          text: I18n.t('Please select a linked partner app when matches are available'),
          type: 'error',
        },
      ]
    : []

  const getPlaceholder = (): string => {
    if (loading) {
      return I18n.t('Checking')
    }
    if (error) {
      return I18n.t('Error loading products')
    }
    if (!hasMatches) {
      return I18n.t('No products match these URIs')
    }
    return I18n.t('Select a linked partner app')
  }

  const renderBeforeInput = loading ? (
    <Spinner renderTitle={I18n.t('Checking')} size="x-small" />
  ) : null

  const getOptionLabel = (registration: ApiRegistration): string => {
    return `${registration.company_name} - ${registration.tool_name}`
  }

  const utidTooltip = I18n.t(
    'We suggest apps based on the redirect URIs. Please select an app to help us understand how our APIs are being used. ' +
      'If you don’t see your specific app, select the closest match.',
  )

  return (
    <SimpleSelect
      data-testid="utid-selector"
      id="dev-key-utid-selector"
      renderLabel={
        <>
          {I18n.t('Linked Partner App:')}
          {isRequired && <span aria-hidden="true"> *</span>}
          &nbsp;
          <Tooltip renderTip={utidTooltip} on={['hover', 'focus']} color="primary">
            <IconButton
              renderIcon={IconInfoLine}
              withBackground={false}
              withBorder={false}
              screenReaderLabel={utidTooltip}
              size="small"
              data-pendo="dev-key-utid-selector-info"
              data-testid="dev-key-utid-selector-info"
            />
          </Tooltip>
        </>
      }
      isRequired={false}
      disabled={!hasMatches || loading}
      value={loading ? '' : selectedUtid || ''}
      onChange={(_e, {value}) => {
        onUtidChange((value as string) || null)
      }}
      messages={validationMessages}
      placeholder={getPlaceholder()}
      renderBeforeInput={renderBeforeInput}
    >
      {matches.map(registration => (
        <SimpleSelect.Option
          key={registration.unified_tool_id}
          id={registration.unified_tool_id}
          value={registration.unified_tool_id}
        >
          {getOptionLabel(registration)}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}
