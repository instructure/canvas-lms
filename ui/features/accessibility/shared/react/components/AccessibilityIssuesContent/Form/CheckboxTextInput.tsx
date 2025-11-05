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
  useEffect,
  forwardRef,
  useRef,
  useImperativeHandle,
  useCallback,
  useContext,
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

import {AccessibilityCheckerContext} from '../../../contexts/AccessibilityCheckerContext'
import type {AccessibilityCheckerContextType} from '../../../contexts/AccessibilityCheckerContext'
import {GenerateResponse} from '../../../types'
import {getAsContentItemType} from '../../../utils/apiData'
import {stripQueryString} from '../../../utils/query'
import {FormComponentHandle, FormComponentProps} from './index'
import {useAccessibilityScansStore} from '../../../stores/AccessibilityScansStore'
import {useShallow} from 'zustand/react/shallow'

const I18n = createI18nScope('accessibility_checker')

const CheckboxTextInput: React.FC<FormComponentProps & React.RefAttributes<FormComponentHandle>> =
  forwardRef<FormComponentHandle, FormComponentProps>(
    ({issue, value, error, onChangeValue, onReload}: FormComponentProps, ref) => {
      const checkboxRef = useRef<HTMLInputElement | null>(null)
      const textAreaRef = useRef<HTMLTextAreaElement | null>(null)
      const isFirstRender = useRef(true)
      const [isChecked, setChecked] = useState(false)
      const [generateLoading, setGenerateLoading] = useState(false)
      const [generationError, setGenerationError] = useState<string | null>(null)
      const {selectedItem} = useContext(
        AccessibilityCheckerContext,
      ) as Partial<AccessibilityCheckerContextType>
      const isAiGenerationEnabled = useAccessibilityScansStore(
        useShallow(state => state.aiGenerationEnabled),
      )

      const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
        setChecked(e.target.checked)
      }, [])

      const handleTextAreaChange = useCallback(
        (e: React.ChangeEvent<HTMLTextAreaElement>) => {
          onChangeValue(e.target.value)
        },
        [onChangeValue],
      )

      useImperativeHandle(ref, () => ({
        focus: () => {
          if (isChecked) {
            checkboxRef.current?.focus()
          } else {
            textAreaRef.current?.focus()
          }
        },
      }))

      useEffect(() => {
        isFirstRender.current = true
      }, [issue])

      useEffect(() => {
        if (isChecked && value) {
          onChangeValue('')
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
      }, [isChecked])

      useEffect(() => {
        // Skip the first render to avoid calling onReload on initial mount
        if (isFirstRender.current) {
          isFirstRender.current = false
          return
        }

        // Since the checkbox text input does not have an apply button
        // we need to reload the preview when the value changes
        onReload?.(value)
        // eslint-disable-next-line react-hooks/exhaustive-deps
      }, [value])

      const handleGenerateClick = () => {
        setGenerateLoading(true)
        setGenerationError(null)
        doFetchApi<GenerateResponse>({
          path: `${stripQueryString(window.location.href)}/generate`,
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
          .then(result => {
            return result.json
          })
          .then(resultJson => {
            onChangeValue(resultJson?.value)
          })
          .catch(error => {
            console.error('Error generating text input:', error)
            const statusCode = error?.response?.status || 0

            if (statusCode == 429) {
              setGenerationError(
                I18n.t(
                  'You have exceeded your daily limit for alt text generation. (You can generate alt text for 300 images per day.) Please try again after a day, or enter alt text manually.',
                ),
              )
            } else {
              setGenerationError(
                I18n.t(
                  'There was an error generating alt text. Please try again, or enter it manually.',
                ),
              )
            }
          })
          .finally(() => setGenerateLoading(false))
      }

      return (
        <>
          <View as="div">
            <Checkbox
              inputRef={el => (checkboxRef.current = el)}
              label={issue.form.checkboxLabel}
              checked={isChecked}
              onChange={handleChange}
              messages={error && isChecked ? [{text: error, type: 'newError'}] : []}
            />
          </View>
          <View as="div" margin="small 0 medium">
            <Text size="small" color="secondary">
              {issue.form.checkboxSubtext}
            </Text>
          </View>
          <View as="div" margin="small 0">
            <TextArea
              data-testid="checkbox-text-input-form"
              textareaRef={el => (textAreaRef.current = el)}
              label={issue.form.label}
              disabled={isChecked}
              value={value || ''}
              onChange={handleTextAreaChange}
              messages={error && !isChecked ? [{text: error, type: 'newError'}] : []}
            />
          </View>
          <Flex as="div" justifyItems="space-between" margin="small small">
            <Flex.Item>
              <Text size="small" color="secondary">
                {issue.form.inputDescription}
              </Text>
            </Flex.Item>
            <Flex.Item>
              <Text size="small" color="secondary">
                {value?.length || 0}/{issue.form.inputMaxLength}
              </Text>
            </Flex.Item>
          </Flex>
          {isAiGenerationEnabled && (
            <>
              <Flex as="div" margin="small 0">
                <Flex.Item>
                  <Button
                    color="ai-primary"
                    renderIcon={() => <IconAiSolid />}
                    onClick={handleGenerateClick}
                    disabled={generateLoading}
                  >
                    {issue.form.generateButtonLabel}
                  </Button>
                </Flex.Item>
                {generateLoading ? (
                  <Flex.Item>
                    <Spinner
                      size="x-small"
                      renderTitle={I18n.t('Generating...')}
                      margin="0 small 0 0"
                    />
                  </Flex.Item>
                ) : (
                  <></>
                )}
              </Flex>
              {generationError !== null ? (
                <Flex>
                  <Flex.Item>
                    <Alert variant="error" renderCloseButtonLabel="Close" timeout={5000}>
                      {generationError}
                    </Alert>
                  </Flex.Item>
                </Flex>
              ) : (
                <></>
              )}
            </>
          )}
        </>
      )
    },
  )

export default CheckboxTextInput
