/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {forwardRef, useContext, useRef, useImperativeHandle, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useTranslationStore} from '../../hooks/useTranslationStore'

const I18n = createI18nScope('discussion_posts')

export const TranslationControls = forwardRef((props, ref) => {
  const languageNotSelectedErrorMessage = I18n.t('Please select a language.')
  const languageAlreadyActiveErrorMessage = I18n.t('Already translated into the selected language.')

  // @ts-expect-error TS2339 (typescriptify)
  const {translationLanguages} = useContext(DiscussionManagerUtilityContext)
  const activeLangauge = useTranslationStore(state => state.activeLanguage)

  const inputRef = useRef()

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  const handleSelectOption = (_event, {value}) => {
    // @ts-expect-error TS7006 (typescriptify)
    const result = translationLanguages.current.find(lang => lang.id === value)

    if (!result) return

    // @ts-expect-error TS2339 (typescriptify)
    if (ENV.ai_translation_improvements) {
      // @ts-expect-error TS2339 (typescriptify)
      props.onSetIsLanguageNotSelectedError(false)
      // @ts-expect-error TS2339 (typescriptify)
      props.onSetIsLanguageAlreadyActiveError(false)
    }

    // @ts-expect-error TS2339 (typescriptify)
    props.onSetSelectedLanguage(value)
  }

  const reset = () => {
    // @ts-expect-error TS2339 (typescriptify)
    props.onSetSelectedLanguage('')

    // @ts-expect-error TS2339 (typescriptify)
    if (props.onSetIsLanguageNotSelectedError) {
      // @ts-expect-error TS2339 (typescriptify)
      props.onSetIsLanguageNotSelectedError(false)
    }
    // @ts-expect-error TS2339 (typescriptify)
    if (props.onSetIsLanguageAlreadyActiveError) {
      // @ts-expect-error TS2339 (typescriptify)
      props.onSetIsLanguageAlreadyActiveError(false)
    }
  }

  useImperativeHandle(ref, () => ({
    reset,
  }))

  const messages = []
  let assistiveText = ''

  // @ts-expect-error TS2339 (typescriptify)
  if (props.isLanguageNotSelectedError) {
    messages.push({type: 'error', text: languageNotSelectedErrorMessage})
    assistiveText = languageNotSelectedErrorMessage
    // @ts-expect-error TS2339 (typescriptify)
  } else if (props.isLanguageAlreadyActiveError) {
    messages.push({type: 'error', text: languageAlreadyActiveErrorMessage})
    assistiveText = languageAlreadyActiveErrorMessage
  }

  useEffect(() => {
    // @ts-expect-error TS2339 (typescriptify)
    if (props.isLanguageNotSelectedError || props.isLanguageAlreadyActiveError) {
      // @ts-expect-error TS2339 (typescriptify)
      inputRef.current?.focus()
    }
    // @ts-expect-error TS2339 (typescriptify)
  }, [props.isLanguageNotSelectedError, props.isLanguageAlreadyActiveError])

  return (
    // @ts-expect-error TS2322 (typescriptify)
    <View ref={ref} as="div">
      <SimpleSelect
        renderLabel=""
        assistiveText={assistiveText}
        aria-labelledby="translate-select-label"
        placeholder={I18n.t('Select a language...')}
        // @ts-expect-error TS2339 (typescriptify)
        value={props.selectedLanguage}
        defaultValue={
          activeLangauge
            ? // @ts-expect-error TS7031 (typescriptify)
              translationLanguages?.current?.find(({id}) => id === activeLangauge)?.name
            : ''
        }
        // @ts-expect-error TS2322 (typescriptify)
        onChange={handleSelectOption}
        // @ts-expect-error TS2322 (typescriptify)
        messages={messages}
        inputRef={el => {
          // @ts-expect-error TS2322 (typescriptify)
          inputRef.current = el
        }}
      >
        {/* @ts-expect-error TS7031 (typescriptify) */}
        {translationLanguages.current.map(({id, name}) => (
          <SimpleSelect.Option key={id} id={id} value={id}>
            {name}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </View>
  )
})

TranslationControls.propTypes = {
  // @ts-expect-error TS2353 (typescriptify)
  isLanguageAlreadyActiveError: PropTypes.bool,
  onSetIsLanguageAlreadyActiveError: PropTypes.func,
  isLanguageNotSelectedError: PropTypes.bool,
  onSetIsLanguageNotSelectedError: PropTypes.func,
  onSetSelectedLanguage: PropTypes.func,
  selectedLanguage: PropTypes.string,
}
