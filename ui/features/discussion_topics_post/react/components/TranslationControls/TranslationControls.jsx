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

// TODO: Translate the language co> ntrols into the canvas target locale.
export const TranslationControls = forwardRef((props, ref) => {
  const {translationLanguages, setTranslateTargetLanguage} = useContext(
    DiscussionManagerUtilityContext,
  )
  const [input, setInput] = useState('')
  const [selected, setSelected] = useState(null)

  const handleSelect = selectedArray => {
    const id = selectedArray[0]
    const result = translationLanguages.current.find(({id: _id}) => id === _id)

    if (!result) {
      return
    }

    setInput(result.name)
    setSelected(result.id)

    if (props.setTranslationLanguage) {
      props.setTranslationLanguage(result.id)
    } else {
      setTranslateTargetLanguage(result.id)
    }
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
    setSelected(null)
  }

  useImperativeHandle(ref, () => ({
    reset,
  }))

  return (
    <View ref={ref} as="div" margin="x-small 0 0">
      <CanvasMultiSelect
        label={I18n.t('Translate to')}
        onChange={handleSelect}
        inputValue={input}
        onInputChange={e => setInput(e.target.value)}
        width="360px"
        placeholder={I18n.t('Language')}
      >
        {filteredLanguages.map(({id, name}) => (
          <CanvasMultiSelect.Option key={id} id={id} value={id} isSelected={id === selected}>
            {name}
          </CanvasMultiSelect.Option>
        ))}
      </CanvasMultiSelect>
    </View>
  )
})

TranslationControls.propTypes = {
  setTranslationLanguage: PropTypes.func,
}
