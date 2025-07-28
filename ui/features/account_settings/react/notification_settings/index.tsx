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

import React, {useState, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {Button, type ButtonProps} from '@instructure/ui-buttons'
import {SimpleSelect, type SimpleSelectProps} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {TextInput, type TextInputProps} from '@instructure/ui-text-input'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('account_notification_settings')

export interface NotificationSettingsProps {
  accountId: string
  externalWarning: boolean
  customName?: string
  defaultName: string
  customNameOption: 'default' | 'custom'
}

type FormMessage = Required<TextInputProps>['messages'][0]
type SimpleSelectOnChange = SimpleSelectProps['onChange']
type ButtonInteraction = ButtonProps['interaction']

export default function NotificationSettings(props: NotificationSettingsProps): JSX.Element {
  const [externalWarning, setExternalWarning] = useState(props.externalWarning)
  const [customNameOption, setCustomNameOption] = useState(props.customNameOption)
  const [customName, setCustomName] = useState(props.customName?.trim())
  const [error, setError] = useState(false)
  const [updateButtonDisabled, setUpdateButtonDisabled] = useState<ButtonInteraction>('enabled')
  const customNameInputElement = useRef<HTMLElement | null>(null)

  function validateCustomName(value: string | undefined): boolean {
    if (customNameOption !== 'custom') return true
    const isEmpty = typeof value === 'undefined' || value.trim().length === 0
    setError(isEmpty)
    return !isEmpty
  }

  function renderFromSettings(): JSX.Element {
    const handleSelect: SimpleSelectOnChange = (_e, {value}) => {
      if (value === 'default' || value == 'custom') {
        setCustomNameOption(value)
        if (value === 'custom') return
        setCustomName('')
        setError(false)
        return
      }
    }

    const handleCustomNameChange: TextInputProps['onChange'] = (_e, v) => {
      const value = v.trimStart()
      validateCustomName(value)
      setCustomName(value)
    }

    function customNameMessages(): FormMessage[] {
      const message: FormMessage = error
        ? {type: 'newError', text: I18n.t('Please enter a custom "From" name.')}
        : {
            type: 'hint',
            text: I18n.t('This will replace all other branding sent in Canvas notifications.'),
          }
      return [message]
    }

    return (
      <>
        <Heading level="h2" margin="medium 0 x-small 0">
          {I18n.t('Email Notification "From" Settings')}
        </Heading>
        <Text>
          {I18n.t(
            'This setting allows the Admin to brand or label all the "From" text on all notifications sent from Canvas for this Account.',
          )}
        </Text>
        <Flex margin="large 0" alignItems="start">
          <Flex.Item>
            <SimpleSelect
              renderLabel={I18n.t('Email "From" Format')}
              value={customNameOption}
              onChange={handleSelect}
              data-testid="from-select"
            >
              <SimpleSelect.Option id="custom-name-option-default" value="default">
                {I18n.t('Default Canvas Setting')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="custom-name-option-custom" value="custom">
                {I18n.t('Custom "From" Name')}
              </SimpleSelect.Option>
            </SimpleSelect>
          </Flex.Item>
          {customNameOption === 'custom' && (
            <Flex.Item margin="0 0 0 medium">
              <TextInput
                inputRef={ref => {
                  customNameInputElement.current = ref
                }}
                renderLabel={I18n.t('"From" Name')}
                isRequired={true}
                value={customName ?? ''}
                onChange={handleCustomNameChange}
                onBlur={() => {
                  validateCustomName(customName)
                }}
                messages={customNameMessages()}
                data-testid="custom-name-input"
              />
            </Flex.Item>
          )}
        </Flex>
      </>
    )
  }

  function renderSampleHeaders(): JSX.Element {
    const locales = ENV?.LOCALES || navigator.languages || ['en-US']
    const dateFormat = new Intl.DateTimeFormat('en-US', {dateStyle: 'medium', timeStyle: 'short'})
    const date = dateFormat.format(new Date())
    const cellStyling = {padding: '0.25rem 2rem'}
    const name =
      customNameOption === 'custom'
        ? customName || `[${I18n.t('Custom text').toLocaleUpperCase(locales)}]`
        : props.defaultName
    return (
      <View as="div" background="secondary" margin="medium 0" padding="small" borderRadius="small">
        <Text as="div" weight="bold" lineHeight="double">
          {I18n.t('Example')}
        </Text>
        <table>
          <tbody>
            <tr>
              <td>{I18n.t('From')}</td>
              <td style={cellStyling}>{name} &lt;notifications@instructure.com&gt;</td>
            </tr>
            <tr>
              <td>{I18n.t('Subject')}</td>
              <td style={cellStyling}>{I18n.t('Recent Canvas Notifications')}</td>
            </tr>
            <tr>
              <td>{I18n.t('Date')}</td>
              <td style={cellStyling}>{date}</td>
            </tr>
            <tr>
              <td>{I18n.t('To')}</td>
              <td style={cellStyling}>recipient@instructure.com</td>
            </tr>
            <tr>
              <td>{I18n.t('Reply-To')}</td>
              <td style={cellStyling}>
                notifications+e79df3ljk09s3jkl09ssljk3lkj2l-10191633@instructure.com
              </td>
            </tr>
          </tbody>
        </table>
      </View>
    )
  }

  function renderExternalServicesNotificationSettings(): JSX.Element {
    return (
      <>
        <Heading level="h2" margin="large 0 medium 0">
          {I18n.t('Notifications Sent to External Services')}
        </Heading>
        <Checkbox
          label={I18n.t('Display one time pop-up warning on Notification Preferences page.')}
          checked={externalWarning}
          onChange={() => setExternalWarning(!externalWarning)}
          data-testid="external-warning"
        />
        <View
          as="div"
          background="secondary"
          margin="medium 0"
          padding="small"
          borderRadius="small"
        >
          <Text as="div" weight="bold" lineHeight="double">
            {I18n.t('Pop-up Message Content')}
          </Text>
          <Text as="div">
            {I18n.t(
              `Notice: Some notifications may contain confidential information. Selecting
              to receive notifications at an email other than your institution provided
              address may result in sending sensitive Canvas course and group information
              outside of the institutional system.`,
            )}
          </Text>
        </View>
      </>
    )
  }

  async function updateSettings(e: React.FormEvent): Promise<void> {
    e.preventDefault()
    const valid = validateCustomName(customName)
    if (!valid) {
      if (customNameInputElement.current) customNameInputElement.current.focus()
      return
    }
    const formData = new FormData()
    formData.append('account[settings][external_notification_warning]', externalWarning ? '1' : '0')
    formData.append('account[settings][outgoing_email_default_name_option]', customNameOption)
    if (customNameOption === 'custom')
      formData.append('account[settings][outgoing_email_default_name]', customName!)
    setUpdateButtonDisabled('disabled')
    try {
      const _response = await doFetchApi({
        method: 'PUT',
        path: `/accounts/${props.accountId}`,
        body: formData,
      })
      // XXX We'd normally just stay on this page and continue to manage the settings state,
      // but because for now this is just a portal inside a much larger ERB-rendered settings
      // page with multiple tabs, it's probably safer to mimic the original "submit" behavior
      // and just reload the page. There also is currently no /api/v1 endpoint that takes a
      // JSON payload to alter an account's settings.
      document.location.reload()
    } catch (error) {
      showFlashError(I18n.t('Failed to update settings'))(error as Error)
    } finally {
      setUpdateButtonDisabled('enabled')
    }
  }

  return (
    <form noValidate={true} onSubmit={updateSettings}>
      {renderFromSettings()}
      {renderSampleHeaders()}
      {renderExternalServicesNotificationSettings()}
      <Button
        color="primary"
        interaction={updateButtonDisabled}
        data-testid="update-button"
        type="submit"
      >
        {I18n.t('Update Settings')}
      </Button>
    </form>
  )
}
