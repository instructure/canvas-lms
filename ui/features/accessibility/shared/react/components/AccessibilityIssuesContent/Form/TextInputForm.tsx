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
import React, {forwardRef, useImperativeHandle, useRef, useState} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {GenerateResponse} from '../../../types'
import {getAsContentItemType} from '../../../utils/apiData'
import {stripQueryString} from '../../../utils/query'
import {FormComponentProps, FormComponentHandle} from './index'
import {useAccessibilityScansStore} from '../../../stores/AccessibilityScansStore'
import {useShallow} from 'zustand/react/shallow'
import {GenerateButton, ButtonLabelByState} from '../GenerateButton'

const I18n = createI18nScope('accessibility_checker')

export const CAPTION_EMPTY_MESSAGE = I18n.t('Caption cannot be empty.')

export const GENERATE_CAPTION_INITIAL_LABEL = I18n.t('Generate caption')
export const GENERATE_CAPTION_LOADING_LABEL = I18n.t('Generating caption...')
export const GENERATE_CAPTION_LOADED_LABEL = I18n.t('Regenerate caption')

export const TextInputFormButtonLabels: ButtonLabelByState = {
  initial: GENERATE_CAPTION_INITIAL_LABEL,
  loading: GENERATE_CAPTION_LOADING_LABEL,
  loaded: GENERATE_CAPTION_LOADED_LABEL,
}

const TextInputForm: React.FC<FormComponentProps & React.RefAttributes<FormComponentHandle>> =
  forwardRef<FormComponentHandle, FormComponentProps>(
    (
      {
        issue,
        error,
        value,
        onValidationChange,
        onChangeValue,
        isDisabled,
        onGenerateLoadingChange,
      }: FormComponentProps,
      ref,
    ) => {
      const [generateLoading, setGenerateLoading] = useState(false)
      const inputRef = useRef<HTMLInputElement | null>(null)
      const [generationError, setGenerationError] = useState<string | null>(null)
      const [isAiTableCaptionGenerationEnabled, selectedItem] = useAccessibilityScansStore(
        useShallow(state => [state.isAiTableCaptionGenerationEnabled, state.selectedScan]),
      )

      useImperativeHandle(ref, () => ({
        focus: () => {
          inputRef.current?.focus()
        },
      }))

      const handleOnChange = (value: string) => {
        onChangeValue(value)

        if (value?.trim().length === 0) {
          onValidationChange?.(false, CAPTION_EMPTY_MESSAGE)
        } else {
          onValidationChange?.(true)
        }
      }

      const handleGenerateClick = () => {
        setGenerateLoading(true)
        setGenerationError(null)
        onGenerateLoadingChange?.(true)

        doFetchApi<GenerateResponse>({
          path: `${stripQueryString(window.location.href)}/generate/table_caption`,
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
            handleOnChange(resultJson?.value || '')
          })
          .catch(error => {
            const statusCode = error?.response?.status || 0

            if (statusCode == 429) {
              setGenerationError(
                I18n.t(
                  'You have exceeded your daily limit for table caption generation. (You can generate captions for 300 tables per day.) Please try again after a day, or enter the caption manually.',
                ),
              )
            } else {
              setGenerationError(
                I18n.t(
                  'There was an error generating table caption. Please try again, or enter it manually.',
                ),
              )
            }
          })
          .finally(() => {
            setGenerateLoading(false)
            onGenerateLoadingChange?.(false)
          })
      }

      return (
        <Flex direction="column" gap="medium">
          <Flex as="div" gap="mediumSmall" direction="column" alignItems="start">
            <TextInput
              data-testid="text-input-form"
              renderLabel={issue.form.label}
              value={value || ''}
              onChange={(_, value) => handleOnChange(value)}
              inputRef={el => (inputRef.current = el)}
              isRequired
              messages={error ? [{text: error, type: 'newError'}] : []}
              interaction={isDisabled || generateLoading ? 'disabled' : 'enabled'}
            />

            {isAiTableCaptionGenerationEnabled && issue.form.canGenerateFix && !isDisabled && (
              <GenerateButton
                handleGenerateClick={handleGenerateClick}
                isLoading={generateLoading}
                buttonLabels={TextInputFormButtonLabels}
              />
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

export default TextInputForm
