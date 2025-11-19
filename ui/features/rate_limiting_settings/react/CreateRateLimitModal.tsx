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

import React, {FormEvent, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {NumberInput} from '@instructure/ui-number-input'
import {TextArea} from '@instructure/ui-text-area'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {View, ViewProps} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {RateLimitSetting} from './RateLimitingSettingsApp'

const I18n = createI18nScope('rate_limiting_settings')

interface CreateRateLimitModalProps {
  open: boolean
  onClose: () => void
  onSuccess: (setting: RateLimitSetting) => void
}

const CreateRateLimitModal: React.FC<CreateRateLimitModalProps> = ({open, onClose, onSuccess}) => {
  const [identifierType, setIdentifierType] = useState('product')
  const [identifierValue, setIdentifierValue] = useState('')
  const [rateLimit, setRateLimit] = useState<string>('')
  const [outflowRate, setOutflowRate] = useState<string>('')
  const [clientName, setClientName] = useState('')
  const [comments, setComments] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [errors, setErrors] = useState<{[key: string]: string}>({})
  const [fieldErrors, setFieldErrors] = useState<{[key: string]: string}>({})

  const validateFields = () => {
    const newFieldErrors: {[key: string]: string} = {}
    let firstInvalidField: string | null = null

    if (!identifierValue.trim()) {
      newFieldErrors.identifier = I18n.t('Identifier is required')
      if (!firstInvalidField) firstInvalidField = 'identifier'
    }

    setFieldErrors(newFieldErrors)

    // Focus the first invalid field
    if (firstInvalidField) {
      setTimeout(() => {
        const element = document.getElementById(`rate-limit-form-${firstInvalidField}`)
        if (element) {
          element.focus()
        }
      }, 0)
    }

    return Object.keys(newFieldErrors).length === 0
  }

  const handleSubmit = async (
    event:
      | React.FormEvent<HTMLFormElement>
      | React.KeyboardEvent<ViewProps>
      | React.MouseEvent<ViewProps>,
  ) => {
    event.preventDefault()

    // Validate required fields
    if (!validateFields()) {
      return
    }

    setSubmitting(true)
    setErrors({})
    setFieldErrors({})

    try {
      const result = await doFetchApi<RateLimitSetting>({
        path: `/accounts/${ENV.ACCOUNT_ID}/rate_limiting_settings`,
        method: 'POST',
        body: {
          rate_limit_setting: {
            type: identifierType,
            identifier: identifierValue,
            ...(rateLimit ? {throttle_high_water_mark: parseInt(rateLimit, 10)} : {}),
            ...(outflowRate ? {throttle_outflow: parseInt(outflowRate, 10)} : {}),
            client_name: clientName,
            comment: comments,
          },
        },
      })

      if (result.json) {
        onSuccess(result.json)

        // Reset form
        setIdentifierType('product')
        setIdentifierValue('')
        setRateLimit('')
        setOutflowRate('')
        setClientName('')
        setComments('')
        setFieldErrors({})
      }
    } catch (error: any) {
      if (error.response) {
        if (error.response.status === 422) {
          try {
            // Parse the response body for validation errors
            const body = await error.response.text()
            const errorData = JSON.parse(body)

            if (errorData.errors) {
              // Handle array of error messages
              const errorMessage = Array.isArray(errorData.errors)
                ? errorData.errors.join(', ')
                : Object.values(errorData.errors).flat().join(', ')
              setErrors({general: errorMessage})
            } else {
              setErrors({general: I18n.t('Validation failed')})
            }
          } catch (e) {
            setErrors({general: I18n.t('Validation failed')})
          }
          return
        }
      }

      showFlashAlert({
        message: I18n.t('Failed to create rate limit setting'),
        type: 'error',
      })
    } finally {
      setSubmitting(false)
    }
  }

  const handleClose = () => {
    if (!submitting) {
      setIdentifierType('product')
      setIdentifierValue('')
      setRateLimit('')
      setOutflowRate('')
      setClientName('')
      setComments('')
      setErrors({})
      setFieldErrors({})
      onClose()
    }
  }

  const handleIdentifierChange = (value: string) => {
    setIdentifierValue(value)
    // Clear field error when user starts typing
    if (fieldErrors.identifier && value.trim()) {
      setFieldErrors(prev => {
        const newErrors = {...prev}
        delete newErrors.identifier
        return newErrors
      })
    }
  }

  const handleIdentifierBlur = () => {
    if (!identifierValue.trim()) {
      setFieldErrors(prev => ({
        ...prev,
        identifier: I18n.t('Identifier is required'),
      }))
    }
  }

  return (
    <Modal
      open={open}
      onDismiss={handleClose}
      size="medium"
      label={I18n.t('Create rate limit')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Create rate limit')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <form onSubmit={handleSubmit}>
          <FormFieldGroup
            description={I18n.t('Create a new rate limit setting')}
            rowSpacing="medium"
          >
            <SimpleSelect
              renderLabel={I18n.t('Type')}
              value={identifierType}
              onChange={(_, {value}) => setIdentifierType(value as string)}
              isRequired
            >
              <SimpleSelect.Option id="product" value="product">
                {I18n.t('Product ID')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="client_id" value="client_id">
                {I18n.t('Client ID')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="custom" value="custom">
                {I18n.t('Custom')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="lti_advantage" value="lti_advantage">
                {I18n.t('LTI Advantage')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="service_user_key" value="service_user_key">
                {I18n.t('Service User Key')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="token" value="token">
                {I18n.t('Token')}
              </SimpleSelect.Option>
            </SimpleSelect>

            <TextInput
              renderLabel={I18n.t('Identifier')}
              value={identifierValue}
              onChange={(_, value) => handleIdentifierChange(value)}
              onBlur={handleIdentifierBlur}
              placeholder={I18n.t(
                'Enter the identifier for the rate limit (e.g., UTID, client ID)',
              )}
              isRequired
              messages={
                fieldErrors.identifier ? [{text: fieldErrors.identifier, type: 'error'}] : []
              }
              id="rate-limit-form-identifier"
            />

            <NumberInput
              renderLabel={I18n.t('High water mark (maximum will be 200 less)')}
              value={rateLimit}
              allowStringValue={true}
              onChange={(_, value) => setRateLimit(value)}
              onIncrement={() =>
                setRateLimit(prev => String(Math.max(1, parseInt(prev || '0', 10) + 1)))
              }
              onDecrement={() =>
                setRateLimit(prev => String(Math.max(0, parseInt(prev || '0', 10) - 1)))
              }
              placeholder={I18n.t('Enter the high water mark value (optional)')}
            />

            <NumberInput
              renderLabel={I18n.t('Outflow rate')}
              value={outflowRate}
              allowStringValue={true}
              onChange={(_, value) => setOutflowRate(value)}
              onIncrement={() =>
                setOutflowRate(prev => String(Math.max(1, parseInt(prev || '0', 10) + 1)))
              }
              onDecrement={() =>
                setOutflowRate(prev => String(Math.max(0, parseInt(prev || '0', 10) - 1)))
              }
              placeholder={I18n.t('Enter the outflow rate value (optional)')}
            />

            <TextInput
              renderLabel={I18n.t('Client name (optional)')}
              value={clientName}
              onChange={(_, value) => setClientName(value)}
              placeholder={I18n.t('Enter a friendly name for this client')}
            />

            <TextArea
              label={I18n.t('Comments')}
              value={comments}
              onChange={e => setComments(e.target.value)}
              placeholder={I18n.t('Enter any comments about this rate limit')}
              maxLength={1000}
              height="6rem"
            />

            {errors.general && (
              <View as="div" margin="small none none none">
                <Text color="danger">{errors.general}</Text>
              </View>
            )}
          </FormFieldGroup>
        </form>
      </Modal.Body>
      <Modal.Footer>
        <Flex direction="row" justifyItems="end">
          <Flex.Item>
            <Button margin="none small none none" onClick={handleClose} disabled={submitting}>
              {I18n.t('Cancel')}
            </Button>
            <Button onClick={handleSubmit} color="primary" disabled={submitting}>
              {submitting ? I18n.t('Creating...') : I18n.t('Create')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default CreateRateLimitModal
