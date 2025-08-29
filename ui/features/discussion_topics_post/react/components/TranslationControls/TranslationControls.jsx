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

import React, {
  forwardRef,
  useContext,
  useState,
  useRef,
  useImperativeHandle,
  useEffect,
} from 'react'
import {View} from '@instructure/ui-view'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import {SimpleSelect} from '@instructure/ui-simple-select'

const I18n = createI18nScope('discussion_posts')

export const TranslationControls = forwardRef((props, ref) => {
  const languageNotSelectedErrorMessage = I18n.t('Please select a language.')
  const languageAlreadyActiveErrorMessage = I18n.t('Already translated into the selected language.')

  const {translationLanguages, setTranslateTargetLanguage} = useContext(
    DiscussionManagerUtilityContext,
  )

  const inputRef = useRef()
  const [selectedLanguage, setSelectedLanguage] = useState(props.selectedLanguage || '')

  const handleSelectOption = (_event, {value}) => {
    const result = translationLanguages.current.find(lang => lang.id === value)

    if (!result) return

    if (ENV.ai_translation_improvements) {
      props.onSetIsLanguageNotSelectedError(false)
      props.onSetIsLanguageAlreadyActiveError(false)
      props.onSetSelectedLanguage(result.id)
    } else {
      setTranslateTargetLanguage(result.id)
    }

    setSelectedLanguage(value)
  }

  const reset = () => {
    setSelectedLanguage('')

    if (props.onSetSelectedLanguage) {
      props.onSetSelectedLanguage(null)
    }

    if (props.onSetIsLanguageNotSelectedError) {
      props.onSetIsLanguageNotSelectedError(false)
    }
    if (props.onSetIsLanguageAlreadyActiveError) {
      props.onSetIsLanguageAlreadyActiveError(false)
    }
  }

  useImperativeHandle(ref, () => ({
    reset,
  }))

  const messages = []
  let assistiveText = ''

  if (props.isLanguageNotSelectedError) {
    messages.push({type: 'error', text: languageNotSelectedErrorMessage})
    assistiveText = languageNotSelectedErrorMessage
  } else if (props.isLanguageAlreadyActiveError) {
    messages.push({type: 'error', text: languageAlreadyActiveErrorMessage})
    assistiveText = languageAlreadyActiveErrorMessage
  }

  useEffect(() => {
    if (props.isLanguageNotSelectedError || props.isLanguageAlreadyActiveError) {
      inputRef.current?.focus()
    }
  }, [props.isLanguageNotSelectedError, props.isLanguageAlreadyActiveError])

  return (
    <View ref={ref} as="div">
      <SimpleSelect
        renderLabel=""
        assistiveText={assistiveText}
        aria-labelledby="translate-select-label"
        placeholder={I18n.t('Select a language...')}
        value={selectedLanguage}
        defaultValue={''}
        onChange={handleSelectOption}
        messages={messages}
        inputRef={el => {
          inputRef.current = el
        }}
      >
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
  selectedLanguage: PropTypes.string,
  onSetSelectedLanguage: PropTypes.func,
  isLanguageAlreadyActiveError: PropTypes.bool,
  onSetIsLanguageAlreadyActiveError: PropTypes.func,
  isLanguageNotSelectedError: PropTypes.bool,
  onSetIsLanguageNotSelectedError: PropTypes.func,
}
