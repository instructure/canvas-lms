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

import React, { useState, useRef, useMemo } from 'react'
import { Flex } from '@instructure/ui-flex'
import { Text } from '@instructure/ui-text'
import { RadioInput } from '@instructure/ui-radio-input'
import CanvasMultiSelect from '@canvas/multi-select/react'
import { useScope as createI18nScope } from '@canvas/i18n'
import { Language } from './TranslationControls'
import { Button } from '@instructure/ui-buttons'
import { View } from '@instructure/ui-view'
import AiIcon from '@canvas/ai-icon'
import { useTranslationContext } from '../../hooks/useTranslationContext'

const I18n = createI18nScope('conversations_2')

interface Props {
  asPrimary: boolean | null,
  onSetPrimary: (value: boolean) => void
}

const TranslationOptions: React.FC<Props> = ({ asPrimary, onSetPrimary }) => {
  // @ts-expect-error
  const languages = useRef<Language[]>(ENV?.inbox_translation_languages ?? [])
  const [input, setInput] = useState("")
  const [selectedId, setSelectedId] = useState<Language['id'] | null>(null)

  const { setTranslationTargetLanguage, translateBody, translating: translationLoading } = useTranslationContext()

  const handleChange = (selectedArray: string[]) => {
    const id = selectedArray[0]
    const result = languages.current.find(({ id: _id }) => id === _id)

    if (!result) {
      return
    }

    if (selectedId !== result.id) {
      setInput(result.name)
      setSelectedId(result.id)
      setTranslationTargetLanguage(result.id)
    }

  }

  const handleSubmit = () => {
    if (!input) {
      return
    }

    if (!selectedId) {
      const result = languages.current.find(({ name }) => name === input)

      if (result) {
        setSelectedId(result.id)
      } else {

      // TODO: error handling
      return
      }
    }

    if (asPrimary === null) {
      onSetPrimary(false)
    }

    translateBody(asPrimary === null ? false : asPrimary)
  }


  const filteredLanguages: Language[] = useMemo(() => {
    if (!input) {
      return languages.current
    }

    return languages.current.filter(({ name }) => name.toLowerCase().startsWith(input.toLowerCase()))
  }, [languages, input])

  const isDisabled = !input || translationLoading

  return (
    <View>
      <Flex direction="column">
        <Flex.Item overflowY="visible" padding="small small 0 small">
          <Flex margin="0 0 medium 0" gap="mediumSmall" alignItems="end">
            <Flex.Item shouldGrow>
              <CanvasMultiSelect
                label={I18n.t("Translate To")}
                placeholder={I18n.t("Select a language...")}
                onChange={handleChange}
                inputValue={input}
                onInputChange={e => setInput(e.target.value)}
              >
                {filteredLanguages.map(({ id, name }) => (
                  <CanvasMultiSelect.Option
                    key={id}
                    label={name}
                    id={id}
                    value={name}
                    isSelected={id === selectedId}
                  >
                    {name}
                  </CanvasMultiSelect.Option>
                ))}
              </CanvasMultiSelect>
            </Flex.Item>
            <Flex.Item>
              <Button renderIcon={AiIcon} color="secondary" disabled={isDisabled} onClick={handleSubmit}>{I18n.t("Translate")}</Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item padding="0 small">
          <Flex justifyItems="start" gap="medium" margin="0 0 medium 0" padding="x-small 0">
            <Flex.Item>
              <RadioInput
                label={I18n.t("Show translation second")}
                value="secondary"
                name="secondary"
                checked={asPrimary === false}
                onChange={() => onSetPrimary(false)}
              />
            </Flex.Item>
            <Flex.Item>
              <RadioInput
                label={I18n.t("Show translation first")}
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
        <Text color="secondary" size="small">{I18n.t("This translation is generated by AI. Please note that the output may not always be accurate.")}</Text>
      </Flex>
    </View>
  )
}

export default TranslationOptions
