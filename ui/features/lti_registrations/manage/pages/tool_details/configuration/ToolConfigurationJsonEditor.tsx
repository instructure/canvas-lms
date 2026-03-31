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

import * as React from 'react'
import {unstable_usePrompt, useNavigate, useOutletContext} from 'react-router-dom'
import type {ToolDetailsOutletContext} from '../ToolDetails'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextArea} from '@instructure/ui-text-area'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {ToolConfigurationFooter} from './ToolConfigurationFooter'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useUpdateRegistrationJson} from '../../../api/registrations'

const I18n = createI18nScope('lti_registrations')

const onBeforeUnload = (formIsDirty: boolean) => async (e: BeforeUnloadEvent) => {
  if (formIsDirty) {
    e.preventDefault()
    return ''
  }
}

export const ToolConfigurationJsonEditor = () => {
  const {registration} = useOutletContext<ToolDetailsOutletContext>()
  const updateMutation = useUpdateRegistrationJson()
  const navigate = useNavigate()

  const initialJson = React.useMemo(
    () => JSON.stringify(registration.configuration, null, 2),
    [registration],
  )

  const [jsonValue, setJsonValue] = React.useState(initialJson)
  const [validationError, setValidationError] = React.useState<string | null>(null)
  const [isDirty, setIsDirty] = React.useState(false)

  const unloadHandler = React.useCallback(onBeforeUnload(isDirty), [isDirty])
  React.useEffect(() => {
    window.addEventListener('beforeunload', unloadHandler)
    return () => {
      window.removeEventListener('beforeunload', unloadHandler)
    }
  }, [unloadHandler])

  unstable_usePrompt({
    message: I18n.t('You have unsaved changes. Are you sure you want to leave?'),
    when: isDirty,
  })

  const handleChange = React.useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      const value = e.currentTarget.value
      setJsonValue(value)
      setIsDirty(value !== initialJson)
      setValidationError(null)
    },
    [initialJson],
  )

  const validateJson = React.useCallback(() => {
    try {
      JSON.parse(jsonValue)
      setValidationError(null)
      return true
    } catch {
      const errorMessage = I18n.t('Invalid JSON syntax')
      setValidationError(errorMessage)
      return false
    }
  }, [jsonValue])

  const handleSave = React.useCallback(async () => {
    if (!validateJson()) {
      return
    }

    try {
      await updateMutation.mutateAsync({
        accountId: registration.account_id,
        registrationId: registration.id,
        jsonConfig: jsonValue,
      })

      window.removeEventListener('beforeunload', unloadHandler)
      setIsDirty(false)

      showFlashAlert({
        message: I18n.t('Configuration has been saved successfully.'),
        type: 'success',
        politeness: 'polite',
      })

      // setTimeout needed to wait one tick for react router's unstable_usePrompt
      // to catch up to the dirty state
      setTimeout(() => {
        navigate(`/manage/${registration.id}/configuration`, {replace: true})
      })
    } catch (error: unknown) {
      errorMessagesForConfigurationUpdate(error).then(messages => {
        showFlashAlert({
          message: messages.join(', '),
          type: 'error',
          politeness: 'assertive',
        })
      })
    }
  }, [validateJson, updateMutation, registration, jsonValue, unloadHandler, navigate])

  const handleCancel = React.useCallback(() => {
    navigate(`/manage/${registration.id}/configuration`, {replace: true})
  }, [navigate, registration.id])

  const validationMessages = validationError
    ? [{text: validationError, type: 'error' as const}]
    : []

  return (
    <div>
      <View as="div" margin="0 0 medium 0">
        <Heading level="h3" margin="0 0 small 0">
          {I18n.t('Edit as JSON')}
        </Heading>
        <Text size="small">
          {I18n.t(
            'Use the JSON editor for advanced configurations. Most apps should be managed in the standard settings page. Only make changes here if you are familiar with JSON formatting.',
          )}
        </Text>
        <View as="div" margin="small 0 0 0">
          <Link
            data-pendo="lti-registrations-json-docs-link"
            href="/doc/api/file.lti_dev_key_config.html"
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('View LTI Configuration Documentation')}
          </Link>
        </View>
      </View>

      <View as="div" margin="0 0 medium 0">
        <TextArea
          data-pendo="lti-registrations-json-editor-textarea"
          label={I18n.t('JSON Configuration')}
          value={jsonValue}
          onChange={handleChange}
          onBlur={validateJson}
          height="30em"
          themeOverride={{
            fontFamily: 'monospace',
          }}
          messages={validationMessages}
        />
      </View>

      <ToolConfigurationFooter>
        <Flex direction="row" justifyItems="end" padding="0 small">
          <Flex.Item>
            <Button
              data-pendo="lti-registrations-json-cancel"
              color="secondary"
              margin="0 xx-small 0 0"
              onClick={handleCancel}
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button
              data-pendo="lti-registrations-json-update"
              color="primary"
              interaction={updateMutation.isPending || !!validationError ? 'disabled' : 'enabled'}
              margin="0 0 0 xx-small"
              onClick={handleSave}
            >
              {I18n.t('Update Configuration')}
            </Button>
          </Flex.Item>
        </Flex>
      </ToolConfigurationFooter>
    </div>
  )
}

const errorMessagesForConfigurationUpdate = async (error: unknown): Promise<string[]> => {
  if (error instanceof Error && 'response' in error && error.response instanceof Response) {
    const body = await error.response.json()
    if ('errors' in body && Array.isArray(body.errors)) {
      const errors: Array<unknown> = body.errors
      const errorMessages = errors.flatMap(e => {
        if (typeof e === 'string') {
          return e
        } else {
          return []
        }
      })
      if (errorMessages.length > 0) {
        return errorMessages
      }
    } else if (error instanceof Error) {
      return [error.message]
    }
  }
  return [I18n.t('An error occurred while updating the configuration.')]
}
