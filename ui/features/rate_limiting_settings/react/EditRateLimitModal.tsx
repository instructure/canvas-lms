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
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {NumberInput} from '@instructure/ui-number-input'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {RateLimitSetting} from './RateLimitingSettingsApp'

const I18n = createI18nScope('rate_limiting_settings')

interface EditRateLimitModalProps {
  setting: RateLimitSetting
  onClose: () => void
  onSuccess: (setting: RateLimitSetting) => void
}

const EditRateLimitModal: React.FC<EditRateLimitModalProps> = ({setting, onClose, onSuccess}) => {
  const [rateLimit, setRateLimit] = useState<string>('')
  const [outflowRate, setOutflowRate] = useState<string>('')
  const [clientName, setClientName] = useState('')
  const [comment, setComment] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [errors, setErrors] = useState<{[key: string]: string}>({})
  const [fieldErrors, setFieldErrors] = useState<{[key: string]: string}>({})

  useEffect(() => {
    setRateLimit(setting.rate_limit?.toString() || '')
    setOutflowRate(setting.outflow_rate?.toString() || '')
    setClientName(setting.client_name || '')
    setComment(setting.comment || '')
    setFieldErrors({})
  }, [setting])

  const handleSubmit = async (
    event: React.KeyboardEvent<unknown> | React.MouseEvent<unknown, MouseEvent>,
  ) => {
    event.preventDefault()
    setSubmitting(true)
    setErrors({})
    setFieldErrors({})

    try {
      const result = await doFetchApi<RateLimitSetting>({
        path: `/accounts/${ENV.ACCOUNT_ID}/rate_limiting_settings/${setting.id}`,
        method: 'PUT',
        body: {
          rate_limit_setting: {
            ...(rateLimit ? {throttle_high_water_mark: parseInt(rateLimit, 10)} : {}),
            ...(outflowRate ? {throttle_outflow: parseInt(outflowRate, 10)} : {}),
            client_name: clientName,
            comment: comment,
          },
        },
      })

      if (result.json) {
        onSuccess(result.json)
      }
    } catch (error: any) {
      console.error('Error updating rate limit setting:', error)

      if (error.response && error.response.status === 422) {
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

      showFlashAlert({
        message: I18n.t('Failed to update rate limit setting'),
        type: 'error',
      })
    } finally {
      setSubmitting(false)
    }
  }

  const handleClose = () => {
    if (!submitting) {
      setErrors({})
      setFieldErrors({})
      onClose()
    }
  }

  return (
    <Modal
      open={true}
      onDismiss={handleClose}
      size="medium"
      label={I18n.t('Edit rate limit')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Edit rate limit')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <form>
          <FormFieldGroup description={I18n.t('Edit rate limit settings')} rowSpacing="medium">
            <View as="div" margin="none none small none">
              <Text weight="bold">{I18n.t('Identifier: ')}</Text>
              <Text>{setting.identifier_value}</Text>
            </View>

            <View as="div" margin="none none small none">
              <Text weight="bold">{I18n.t('Type: ')}</Text>
              <Text>{setting.identifier_type}</Text>
            </View>

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
              value={comment}
              onChange={e => setComment(e.target.value)}
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
            <Button color="primary" onClick={handleSubmit} disabled={submitting}>
              {submitting ? I18n.t('Saving...') : I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default EditRateLimitModal
