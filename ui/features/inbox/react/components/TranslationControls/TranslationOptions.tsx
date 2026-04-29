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

import React, {useState, useRef} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
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
  const languages = useRef<Language[]>(
    (ENV as {inbox_translation_languages?: Language[]})?.inbox_translation_languages ?? [],
  )
  const [selectedLanguage, setSelectedLanguage] = useState<Language | null>(null)
  const inputRef = useRef<HTMLInputElement>()

  const translationContext = useTranslationContext()

  const errorMessages = translationContext.errorMessages ?? []
  const {
    setTranslationTargetLanguage,
    translateBody,
    translating: translationLoading,
    setErrorMessages,
  } = translationContext

  const handleSelectOption = (_event: React.ChangeEvent<HTMLSelectElement>, value: string) => {
    const result = languages.current.find(lang => lang.id === value)

    if (!result) return

    setSelectedLanguage(result)
    setTranslationTargetLanguage(result.id)
  }

  const handleSubmit = () => {
    if (translationLoading) return

    if (!selectedLanguage) {
      setErrorMessages([{type: 'newError', text: I18n.t('Please select a language.')}])
      inputRef.current?.focus()
      return
    }

    if (asPrimary === null) {
      onSetPrimary(false)
    }

    setErrorMessages([])
    translateBody(asPrimary ?? false)
  }

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
          display: 'inline-block',
        },
      }}
      render={(responsiveProps: any) => {
        return (
          <View>
            <Flex direction="column">
              <Flex.Item overflowY="visible" padding="small small 0 small">
                <Flex
                  margin="0 0 medium 0"
                  gap="mediumSmall"
                  alignItems="start"
                  direction={responsiveProps.direction}
                >
                  <Flex.Item
                    shouldGrow
                    width={responsiveProps.width}
                    overflowY="hidden"
                    overflowX="hidden"
                  >
                    <SimpleSelect
                      renderLabel={I18n.t('Translate To')}
                      aria-labelledby="langauge-selector-label"
                      placeholder={I18n.t('Select a language...')}
                      value={selectedLanguage?.id}
                      defaultValue={''}
                      onChange={(_event, {value}) =>
                        handleSelectOption(
                          _event as React.ChangeEvent<HTMLSelectElement>,
                          value as string,
                        )
                      }
                      messages={errorMessages}
                      inputRef={el => {
                        inputRef.current = el ?? undefined
                      }}
                    >
                      {languages.current.map(({id, name}) => (
                        <SimpleSelect.Option key={id} id={id} value={id}>
                          {name}
                        </SimpleSelect.Option>
                      ))}
                    </SimpleSelect>
                  </Flex.Item>
                  <Flex.Item
                    width={responsiveProps.width}
                    align={errorMessages.length > 0 ? 'center' : 'end'}
                  >
                    <Button
                      color="ai-primary"
                      aria-label={I18n.t('Ignite AI Translate')}
                      renderIcon={<IconAiSolid />}
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
