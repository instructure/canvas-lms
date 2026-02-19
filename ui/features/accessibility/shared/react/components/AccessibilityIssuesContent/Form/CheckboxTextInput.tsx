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
import React, {
  useState,
  forwardRef,
  useRef,
  useImperativeHandle,
  useCallback,
  useEffect,
  useId,
} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {IconAiSolid} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {FormMessage} from '@instructure/ui-form-field'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {useAccessibilityCheckerContext} from '../../../hooks/useAccessibilityCheckerContext'
import {GenerateResponse} from '../../../types'
import {getAsContentItemType} from '../../../utils/apiData'
import {stripQueryString} from '../../../utils/query'
import {FormComponentHandle, FormComponentProps} from './index'
import {useAccessibilityScansStore} from '../../../stores/AccessibilityScansStore'
import {useShallow} from 'zustand/react/shallow'

const I18n = createI18nScope('accessibility_checker')

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
        previewRef,
        onGenerateLoadingChange,
      }: FormComponentProps,
      ref,
    ) => {
      const [alertMessage, setAlertMessage] = useState<string | null>(null)
      const checkboxRef = useRef<HTMLInputElement | null>(null)
      const textAreaRef = useRef<HTMLTextAreaElement | null>(null)
      const [isChecked, setChecked] = useState(false)
      const [generateLoading, setGenerateLoading] = useState(false)
      const [generationError, setGenerationError] = useState<string | null>(null)
      const {selectedItem} = useAccessibilityCheckerContext()
      const {isAiAltTextGenerationEnabled} = useAccessibilityScansStore(
        useShallow(state => ({
          isAiAltTextGenerationEnabled: state.isAiAltTextGenerationEnabled,
        })),
      )
      const charCountId = useId()

      const validateValue = useCallback(
        (currentValue: string | null, checked: boolean) => {
          if (checked) {
            return {isValid: true, errorMessage: undefined}
          }
          if (currentValue && currentValue.trim()) {
            if (
              !issue.form.inputMaxLength ||
              currentValue.trim().length <= issue.form.inputMaxLength
            ) {
              return {isValid: true, errorMessage: undefined}
            }
            return {
              isValid: false,
              errorMessage: I18n.t('Keep alt text under %{maxLength} characters.', {
                maxLength: issue.form.inputMaxLength,
              }),
            }
          }
          return {isValid: false, errorMessage: I18n.t('Alt text is required.')}
        },
        [issue.form.inputMaxLength],
      )

      // Trigger validation on value or checkbox changes
      useEffect(() => {
        const {isValid, errorMessage} = validateValue(value, isChecked)
        onValidationChange?.(isValid, errorMessage)

        const timeout = setTimeout(() => {
          const inputLength = value?.length ?? 0

          const msg = I18n.t(
            {
              one: '%{count} / %{maxLength} characters entered.',
              other: '%{count} / %{maxLength} characters entered.',
            },
            {count: inputLength, maxLength: issue.form.inputMaxLength},
          )

          setAlertMessage(msg)
        }, 3000)

        return () => clearTimeout(timeout)
      }, [
        value,
        isChecked,
        issue.form.inputMaxLength,
        onValidationChange,
        validateValue,
        setAlertMessage,
      ])

      useEffect(() => {
        const timeout = setTimeout(() => {
          if (alertMessage) {
            setAlertMessage(null)
          }
        }, 3000)

        return () => clearTimeout(timeout)
      }, [alertMessage, setAlertMessage])

      const handleCheckboxValueChange = useCallback(
        (e: React.ChangeEvent<HTMLInputElement>) => {
          setChecked(e.target.checked)
          if (e.target.checked) {
            onChangeValue('')
          }
        },
        [onChangeValue],
      )

      const handleTextAreaChange = useCallback(
        (e: React.ChangeEvent<HTMLTextAreaElement>) => {
          onChangeValue(e.target.value)
        },
        [onChangeValue],
      )

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

      const resetLoadingState = () => {
        setGenerateLoading(false)
        onGenerateLoadingChange?.(false)
      }

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
            const generatedAltText = resultJson?.value
            onChangeValue(generatedAltText)

            if (previewRef?.current) {
              previewRef.current.update(generatedAltText, resetLoadingState, resetLoadingState)
            } else {
              resetLoadingState()
            }
          })
          .catch(error => {
            console.error('Error generating text input:', error)
            const statusCode = error?.response?.status || 0

            const errorMessage =
              statusCode === 429
                ? I18n.t(
                    'You have exceeded your daily limit for alt text generation. (You can generate alt text for 300 images per day.) Please try again after a day, or enter alt text manually.',
                  )
                : I18n.t(
                    'There was an error generating alt text. Please try again, or enter it manually.',
                  )

            setGenerationError(errorMessage)
            resetLoadingState()
          })
      }

      return (
        <Flex direction="column" gap="mediumSmall">
          <View as="div">
            <Checkbox
              inputRef={el => (checkboxRef.current = el)}
              label={issue.form.checkboxLabel}
              checked={isChecked}
              disabled={isDisabled}
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
          </View>

          <View as="div">
            <TextArea
              data-testid="checkbox-text-input-form"
              textareaRef={el => (textAreaRef.current = el)}
              label={issue.form.label}
              disabled={isChecked || isDisabled}
              value={isChecked ? '' : value || ''}
              onChange={handleTextAreaChange}
              messages={formMessages}
              aria-describedby={charCountId}
            />
          </View>

          {isAiAltTextGenerationEnabled && issue.form.canGenerateFix && (
            <Flex as="div" gap="small" direction="column">
              <Flex as="div" gap="x-small" direction="column">
                <Flex.Item overflowX="visible" overflowY="visible">
                  <Button
                    data-testid="generate-alt-text-button"
                    color="ai-primary"
                    renderIcon={() => <IconAiSolid />}
                    onClick={handleGenerateClick}
                    disabled={generateLoading || isDisabled || !issue.form.isCanvasImage}
                  >
                    {generateLoading ? (
                      <>
                        {issue.form.generateButtonLabel}{' '}
                        <Spinner size="x-small" renderTitle={I18n.t('Generating...')} />
                      </>
                    ) : (
                      issue.form.generateButtonLabel
                    )}
                  </Button>
                </Flex.Item>
                <Flex.Item>
                  <Text size="small">
                    {I18n.t(
                      'AI alt text generation is only available for images uploaded to Canvas.',
                    )}
                  </Text>
                </Flex.Item>
              </Flex>
            </Flex>
          )}

          {generationError && (
            <Flex>
              <Flex.Item>
                <Alert variant="error" renderCloseButtonLabel="Close" timeout={5000}>
                  {generationError}
                </Alert>
              </Flex.Item>
            </Flex>
          )}

          {alertMessage && (
            <Alert
              liveRegion={getLiveRegion}
              liveRegionPoliteness="assertive"
              isLiveRegionAtomic
              screenReaderOnly
            >
              {alertMessage}
            </Alert>
          )}
        </Flex>
      )
    },
  )

export default CheckboxTextInput
