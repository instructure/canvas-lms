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

import {Flex} from '@instructure/ui-flex'
import {RadioInput} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Checkbox} from '@instructure/ui-checkbox'

import React, {useContext, useState, useRef, useEffect} from 'react'
import {ModalBodyContext, signatureSeparator, translationSeparator} from '../../utils/constants'
import {stripSignature} from '../../utils/inbox_translator'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conversations_2')

interface TranslationControlsProps {
  inboxSettingsFeature: boolean
  signature: string
}

const TranslationControls = (props: TranslationControlsProps) => {
  const languages = useRef(ENV?.inbox_translation_languages ?? [])
  const [language, setLanguage] = useState('English')
  const [includeTranslation, setIncludeTranslation] = useState(false)
  const [primary, setIsPrimary] = useState(null)
  const [translated, setTranslated] = useState(false)
  const {
    setMessagePosition,
    messagePosition,
    setTranslationTargetLanguage,
    translateBody,
    setBody,
  } = useContext(ModalBodyContext)

  const handleSelect = (e, {id, value}) => {
    setLanguage(value)
    setTranslationTargetLanguage(id)
  }

  /**
   * Handle placing translated message in primary or secondary position
   * */
  const handleChange = isPrimary => {
    setIsPrimary(isPrimary)
    setMessagePosition(isPrimary ? 'primary' : 'secondary')
    if (!translated) {
      translateBody(isPrimary)
      setTranslated(true)
      return
    }

    setBody(prevBody => {
      let newBody = prevBody
      // Strip the signature
      if (props.inboxSettingsFeature && props.signature !== '') {
        newBody = stripSignature(prevBody)
      }

      // Split on the translation separator
      const [part1, part2] = newBody.split(translationSeparator)
      // Flip the message
      newBody = [part2, part1].join(translationSeparator)

      // Add the signature back in.
      if (props.inboxSettingsFeature && props.signature !== '' && props.signature !== undefined) {
        return [newBody, props.signature].join(signatureSeparator)
      }

      // No signature, return the body flipped.
      return newBody
    })
  }

  const handleIncludeTranslation = shouldInclude => {
    setIncludeTranslation(shouldInclude)
  }

  useEffect(() => {
    if (!includeTranslation && translated) {
      setBody(prevBody => {
        if (props.inboxSettingsFeature && props.signature !== '') {
          prevBody = stripSignature(prevBody)
        }

        const [part1, part2] = prevBody.split(translationSeparator)
        const newBody = messagePosition === 'primary' ? part2 : part1

        if (props.inboxSettingsFeature && props.signature !== '') {
          return [newBody, props.signature].join(signatureSeparator)
        }

        return newBody
      })
      setTranslated(false)
      setIsPrimary(null)
    }
  }, [
    includeTranslation,
    messagePosition,
    props.inboxSettingsFeature,
    props.signature,
    setBody,
    translated,
  ])

  return (
    <>
      <Flex alignItems="start" padding="small small small">
        <Flex.Item>
          <Checkbox
            label={I18n.t('Include translated version of this message')}
            value="medium"
            checked={includeTranslation}
            onChange={() => handleIncludeTranslation(!includeTranslation)}
          />
        </Flex.Item>
      </Flex>
      {includeTranslation && (
        <Flex justifyItems="space-around" alignItems="center" margin="0 0 small">
          <Flex.Item padding="small 0 0">
            <SimpleSelect
              renderLabel={I18n.t('Select Translation Language')}
              value={language}
              onChange={handleSelect}
              width="360px"
            >
              {languages.current.map(({id, name}) => {
                return (
                  <SimpleSelect.Option key={id} id={id} value={name}>
                    {name}
                  </SimpleSelect.Option>
                )
              })}
            </SimpleSelect>
          </Flex.Item>
          <Flex.Item>
            <RadioInput
              label={I18n.t('As secondary')}
              value="secondary"
              name="secondary"
              checked={primary === false}
              onChange={() => handleChange(false)}
            />
          </Flex.Item>
          <Flex.Item>
            <RadioInput
              label={I18n.t('As primary')}
              value="primary"
              name="primary"
              checked={primary === true}
              onChange={() => handleChange(true)}
            />
          </Flex.Item>
        </Flex>
      )}
    </>
  )
}

export default TranslationControls
