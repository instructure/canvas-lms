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
import CanvasMultiSelect from '@canvas/multi-select/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Language} from './TranslationControls'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {IconAiSolid} from '@instructure/ui-icons'
import {useTranslationContext} from '../../hooks/useTranslationContext'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '@canvas/discussions/react/utils'

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
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true}) as any}
      props={{
        mobile: {
          direction: 'column',
          width: '100%',
          display: 'block',
        },
        desktop: {
          direction: 'row',
          width: 'auto',
          display: 'flex',
        },
      }}
      render={(responsiveProps: any) => {
        return (
          <View>
            <Flex direction="column">
              <View as="div" margin="xx-small 0 0 xx-small">
                <label id="langauge-selector-label">
                  <Text weight="bold">{I18n.t('Translate To')}</Text>
                </label>
              </View>
              <Flex.Item overflowY="visible" padding="small small 0 small">
                <Flex
                  margin="0 0 medium 0"
                  gap="mediumSmall"
                  alignItems="start"
                  direction={responsiveProps.direction}
                >
                  <Flex.Item shouldGrow width={responsiveProps.width} overflowY="hidden">
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
                  <Flex.Item width={responsiveProps.width}>
                    <Button
                      color="ai-primary"
                      aria-label={I18n.t('Ignite AI Translate')}
                      renderIcon={<IconAiSolid />}
                      disabled={translationLoading}
                      onClick={handleSubmit}
                      display={responsiveProps.display}
                    >
                      {I18n.t('Translate')}
                    </Button>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item padding="0 small" margin="0 0 medium 0">
                <RadioInputGroup
                  layout="columns"
                  name="translationPlacement"
                  description={I18n.t('Choose placement')}
                >
                  <RadioInput
                    label={I18n.t('Show translation second')}
                    value="secondary"
                    name="secondary"
                    checked={asPrimary === false}
                    onChange={() => onSetPrimary(false)}
                  />
                  <RadioInput
                    label={I18n.t('Show translation first')}
                    value="primary"
                    name="primary"
                    checked={asPrimary === true}
                    onChange={() => onSetPrimary(true)}
                  />
                </RadioInputGroup>
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
      }}
    />
  )
}

export default TranslationOptions
