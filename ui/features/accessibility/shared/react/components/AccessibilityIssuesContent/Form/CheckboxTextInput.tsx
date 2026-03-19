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
import React, {useState, forwardRef, useRef, useImperativeHandle} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import {FormMessage} from '@instructure/ui-form-field'
import {GenerateResponse} from '../../../types'
import {getAsContentItemType} from '../../../utils/apiData'
import {stripQueryString} from '../../../utils/query'
import {FormComponentHandle, FormComponentProps} from './index'
import {useAccessibilityScansStore} from '../../../stores/AccessibilityScansStore'
import {useShallow} from 'zustand/react/shallow'
import {useScreenReaderAlert} from '../../../hooks/useScreenReaderAlert'
import {GenerateButton, ButtonLabelByState} from '../GenerateButton'
import {altTextGenerationErrorMessage} from '../../../utils/altTextErrors'

const I18n = createI18nScope('accessibility_checker')

export const ALT_TEXT_REQUIRED_MESSAGE = I18n.t('Alt text is required.')
export const altTextMaxLengthMessage = (maxLength: number) =>
  I18n.t('Keep alt text under %{count} characters.', {count: maxLength})

const validateAltText = (
  value: string | null,
  checked: boolean,
  inputMaxLength: number | undefined,
): {isValid: boolean; errorMessage: string | undefined} => {
  if (checked) return {isValid: true, errorMessage: undefined}

  const trimmed = value?.trim()
  if (!trimmed) return {isValid: false, errorMessage: ALT_TEXT_REQUIRED_MESSAGE}

  if (inputMaxLength && trimmed.length > inputMaxLength) {
    return {isValid: false, errorMessage: altTextMaxLengthMessage(inputMaxLength)}
  }

  return {isValid: true, errorMessage: undefined}
}

export const GENERATE_ALT_TEXT_INITIAL_LABEL = I18n.t('Generate alt text')
export const GENERATE_ALT_TEXT_LOADING_LABEL = I18n.t('Generating alt text...')
export const GENERATE_ALT_TEXT_LOADED_LABEL = I18n.t('Regenerate alt text')

export const CheckboxTextButtonLabels: ButtonLabelByState = {
  initial: GENERATE_ALT_TEXT_INITIAL_LABEL,
  loading: GENERATE_ALT_TEXT_LOADING_LABEL,
  loaded: GENERATE_ALT_TEXT_LOADED_LABEL,
}

const CheckboxTextInput: React.FC<FormComponentProps & React.RefAttributes<FormComponentHandle>> =
  forwardRef<FormComponentHandle, FormComponentProps>(
    (
      {
        issue,
        value,
        error,
        onChangeValue,
        onValidationChange,
        isDisabled,
        onGenerateLoadingChange,
      }: FormComponentProps,
      ref,
    ) => {
      const checkboxRef = useRef<HTMLInputElement | null>(null)
      const textAreaRef = useRef<HTMLTextAreaElement | null>(null)
      const [isChecked, setChecked] = useState(false)
      const [generateLoading, setGenerateLoading] = useState(false)
      const [generationError, setGenerationError] = useState<string | null>(null)
      const setAlertMessage = useScreenReaderAlert()
      const [isAiAltTextGenerationEnabled, selectedItem] = useAccessibilityScansStore(
        useShallow(state => [state.isAiAltTextGenerationEnabled, state.selectedScan]),
      )

      const updateField = (value: string | null, checked: boolean) => {
        const {isValid, errorMessage} = validateAltText(value, checked, issue.form.inputMaxLength)
        onChangeValue(value)
        onValidationChange?.(isValid, errorMessage)
        if (!isValid && errorMessage) setAlertMessage(errorMessage)
      }

      const handleCheckboxValueChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const checked = e.target.checked
        setChecked(checked)
        updateField('', checked)
      }

      const handleTextAreaChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        updateField(e.target.value, isChecked)
      }

      const shouldShowError = error && !isChecked
      const descriptionMessage: FormMessage = {text: issue.form.inputDescription, type: 'hint'}
      const formMessages: FormMessage[] = shouldShowError
        ? [descriptionMessage, {text: error, type: 'newError'}]
        : [descriptionMessage]

      useImperativeHandle(
        ref,
        () => ({
          focus: () => {
            if (isChecked) {
              checkboxRef.current?.focus()
            } else {
              textAreaRef.current?.focus()
            }
          },
          getValue: () => {
            if (isChecked) {
              return null
            }
            return value || ''
          },
        }),
        [isChecked, value],
      )

      const handleGenerateClick = () => {
        setGenerateLoading(true)
        setGenerationError(null)
        onGenerateLoadingChange?.(true)

        doFetchApi<GenerateResponse>({
          path: `${stripQueryString(window.location.href)}/generate/alt_text`,
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            rule: issue.ruleId,
            path: issue.path,
            value: value,
            content_id: selectedItem?.resourceId,
            content_type: getAsContentItemType(selectedItem?.resourceType),
          }),
        })
          .then(result => result.json)
          .then(resultJson => {
            const generatedAltText = resultJson?.value || ''
            updateField(generatedAltText, isChecked)
          })
          .catch(error => {
            console.error('Error generating text input:', error)
            const statusCode = error?.response?.status || 0

            const errorMessage = altTextGenerationErrorMessage(statusCode)

            setGenerationError(errorMessage)
          })
          .finally(() => {
            setGenerateLoading(false)
            onGenerateLoadingChange?.(false)
          })
      }

      return (
        <Flex direction="column" gap="medium">
          <Checkbox
            data-testid="decorative-img-checkbox"
            inputRef={el => (checkboxRef.current = el)}
            label={issue.form.checkboxLabel}
            checked={isChecked}
            disabled={isDisabled || generateLoading}
            messages={[
              {
                text: (
                  <View as="div" margin="0 0 0 medium" themeOverride={{marginMedium: '1.8rem'}}>
                    <Text size="small" color="secondary">
                      {issue.form.checkboxSubtext}
                    </Text>
                  </View>
                ),
                type: 'hint',
              },
            ]}
            onChange={handleCheckboxValueChange}
          />

          <Flex as="div" gap="mediumSmall" direction="column" alignItems="start">
            <TextArea
              data-testid="checkbox-text-input-form"
              textareaRef={el => (textAreaRef.current = el)}
              label={issue.form.label}
              disabled={isChecked || isDisabled || generateLoading}
              value={isChecked ? '' : value || ''}
              onChange={handleTextAreaChange}
              required
              messages={formMessages}
            />

            {isAiAltTextGenerationEnabled && issue.form.canGenerateFix && !isDisabled && (
              <Flex as="div" gap="x-small" direction="column" alignItems="start">
                <GenerateButton
                  handleGenerateClick={handleGenerateClick}
                  isLoading={generateLoading}
                  buttonLabels={CheckboxTextButtonLabels}
                  isDisabled={isChecked || !issue.form.isCanvasImage}
                  pendoId="AiAltTextButtonPushed"
                  selectedItem={selectedItem}
                  ruleId={issue.ruleId}
                />
                {!issue.form.isCanvasImage && (
                  <Text data-testid="alt-text-generation-not-available-message" size="small">
                    {I18n.t(
                      'AI alt text generation is only available for images uploaded to Canvas.',
                    )}
                  </Text>
                )}
              </Flex>
            )}
          </Flex>

          {generationError && (
            <Alert variant="error" renderCloseButtonLabel="Close" timeout={5000}>
              {generationError}
            </Alert>
          )}
        </Flex>
      )
    },
  )

export default CheckboxTextInput
