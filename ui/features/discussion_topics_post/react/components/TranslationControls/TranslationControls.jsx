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

import React, {useContext, useState} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {DiscussionManagerUtilityContext} from '../../utils/constants'

// TODO: Translate the language controls into the canvas target locale.
export const TranslationControls = () => {
  const heading = `Translate Discussion`
  const {translationLanguages, setTranslateTargetLanguage} = useContext(
    DiscussionManagerUtilityContext
  )
  const [language, setLanguage] = useState(translationLanguages.current[0].name)

  const handleSelect = (e, {id, value}) => {
    setLanguage(value)

    // Also set global language in context
    setTranslateTargetLanguage(id)
  }

  return (
    <View as="div" margin="x-small 0 0">
      <SimpleSelect renderLabel={heading} value={language} onChange={handleSelect} width="360px">
        {translationLanguages.current.map(({id, name}) => {
          return (
            <SimpleSelect.Option key={id} id={id} value={name}>
              {name}
            </SimpleSelect.Option>
          )
        })}
      </SimpleSelect>
    </View>
  )
}
