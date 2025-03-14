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

import React, {forwardRef, useContext, useImperativeHandle, useMemo, useState} from 'react'
import CanvasMultiSelect from '@canvas/multi-select/react'
import {View} from '@instructure/ui-view'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

const I18n = createI18nScope('discussion_posts')

export const TranslationControls = forwardRef((props, ref) => {
  const {translationLanguages, setTranslateTargetLanguage} = useContext(
    DiscussionManagerUtilityContext,
  )
  const [input, setInput] = useState('')

  const handleSelect = selectedArray => {
    const id = selectedArray[0]
    const result = translationLanguages.current.find(({id: _id}) => id === _id)

    //TODO: Somehow trigger this function if not valid item is selected
    if(ENV.ai_translation_improvements) {
      props.onSetIsLanguageNotSelectedError(false)
      props.onSetIsLanguageAlreadyActiveError(false)
      props.onSetSelectedLanguage(result.id)
    } else {
      setTranslateTargetLanguage(result.id)
    }

    setInput(result.name)
  }

  const filteredLanguages = useMemo(() => {
    if (!input) {
      return translationLanguages.current
    }

    return translationLanguages.current.filter(({name}) =>
      name.toLowerCase().startsWith(input.toLowerCase()),
    )
  }, [translationLanguages, input])

  const reset = () => {
    setInput('')
    props.onSetSelectedLanguage(null)
  }

  useImperativeHandle(ref, () => ({
    reset,
  }))

  const messages = []

  if (props.isLanguageNotSelectedError) {
    messages.push({type: 'error', text: I18n.t('Please select a language.')})
  } else if (props.isLanguageAlreadyActiveError) {
    messages.push({type: 'error', text: I18n.t('Already translated into the selected language.')})
  }

  return (
    <View ref={ref} as="div">
      <CanvasMultiSelect
        // I couldn't make it work to align the select with the buttons next to it if there's a label
        // So I put the label outside the container as a separate Text element
        // If you know a way to make it work, please do it
        label=""
        aria-labelledby="translate-select-label"
        onChange={handleSelect}
        inputValue={input}
        onInputChange={e => setInput(e.target.value)}
        width="360px"
        placeholder={I18n.t('Select a language...')}
        messages={messages}
      >
        {filteredLanguages.map(({id, name}) => (
          <CanvasMultiSelect.Option key={id} id={id} value={id} isSelected={id === props.selectedLanguage}>
            {name}
          </CanvasMultiSelect.Option>
        ))}
      </CanvasMultiSelect>
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
