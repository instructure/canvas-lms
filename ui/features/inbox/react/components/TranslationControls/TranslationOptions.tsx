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

import React, {useState, useRef, useMemo} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {RadioInput} from '@instructure/ui-radio-input'
import CanvasMultiSelect from '@canvas/multi-select/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Language} from './TranslationControls'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {IconAiLine, IconAiSolid} from '@instructure/ui-icons'
import {useTranslationContext} from '../../hooks/useTranslationContext'
import {canvas} from '@instructure/ui-themes'

const I18n = createI18nScope('conversations_2')

interface Props {
  asPrimary: boolean | null
  onSetPrimary: (value: boolean) => void
}

const TranslationOptions: React.FC<Props> = ({asPrimary, onSetPrimary}) => {
  // @ts-expect-error
  const languages = useRef<Language[]>(ENV?.inbox_translation_languages ?? [])
  const [input, setInput] = useState('')
  const [selectedLanguage, setSelectedLanguage] = useState<Language | null>(null)

  const {
    setTranslationTargetLanguage,
    translateBody,
    translating: translationLoading,
    errorMessages,
    setErrorMessages,
  } = useTranslationContext()

  const handleChange = (selectedArray: string[]) => {
    const id = selectedArray[0]
    const result = languages.current.find(({id: _id}) => id === _id)

    if (!result) {
      return
    }

    if (selectedLanguage?.id !== result.id) {
      setInput(result.name)
      setSelectedLanguage(result)
      setTranslationTargetLanguage(result.id)
    }
  }

  const handleSubmit = () => {
    if (!input) {
      setErrorMessages([{type: 'newError', text: I18n.t('Please select a language')}])
      return
    }

    if (!selectedLanguage) {
      const result = languages.current.find(({name}) => name === input)

      if (!result) {
        setErrorMessages([
          {
            type: 'newError',
            text: I18n.t('There was an error selecting the language. Please try another language.'),
          },
        ])
        return
      }

      setSelectedLanguage(result)
    }

    if (asPrimary === null) {
      onSetPrimary(false)
    }

    setErrorMessages([])
    translateBody(asPrimary === null ? false : asPrimary)
  }

  const filteredLanguages: Language[] = useMemo(() => {
    if (!input) {
      return languages.current
    }

    return languages.current.filter(({name}) => name.toLowerCase().startsWith(input.toLowerCase()))
  }, [languages, input])

  return (
    <View>
      <Flex direction="column">
        <View as="div" margin="xx-small 0 0 xx-small">
          <label id="langauge-selector-label">
            <Text weight="bold">{I18n.t('Translate To')}</Text>
          </label>
        </View>
        <Flex.Item overflowY="visible" padding="small small 0 small">
          <Flex margin="0 0 medium 0" gap="mediumSmall" alignItems="start">
            <Flex.Item shouldGrow>
              <CanvasMultiSelect
                label=""
                aria-labelledby="langauge-selector-label"
                placeholder={I18n.t('Select a language...')}
                onChange={handleChange}
                inputValue={input}
                onInputChange={e => setInput(e.target.value)}
                messages={errorMessages}
              >
                {filteredLanguages.map(({id, name}) => (
                  <CanvasMultiSelect.Option
                    key={id}
                    label={name}
                    id={id}
                    value={name}
                    isSelected={id === selectedLanguage?.id}
                  >
                    {name}
                  </CanvasMultiSelect.Option>
                ))}
              </CanvasMultiSelect>
            </Flex.Item>
            <Flex.Item>
              <Button
                color="ai-primary"
                renderIcon={<IconAiSolid />}
                disabled={translationLoading}
                onClick={handleSubmit}
              >
                {I18n.t('Translate')}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item padding="0 small">
          <Flex justifyItems="start" gap="medium" margin="0 0 medium 0" padding="x-small 0">
            <Flex.Item>
              <RadioInput
                label={I18n.t('Show translation second')}
                value="secondary"
                name="secondary"
                checked={asPrimary === false}
                onChange={() => onSetPrimary(false)}
              />
            </Flex.Item>
            <Flex.Item>
              <RadioInput
                label={I18n.t('Show translation first')}
                value="primary"
                name="primary"
                checked={asPrimary === true}
                onChange={() => onSetPrimary(true)}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      <Flex padding="0 small">
        <Text color="secondary" size="small">
          {I18n.t(
            'This translation is generated by AI. Please note that the output may not always be accurate.',
          )}
        </Text>
      </Flex>
    </View>
  )
}

export default TranslationOptions
