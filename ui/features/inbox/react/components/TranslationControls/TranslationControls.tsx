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

import React, {useContext, useState, useRef, useEffect, useMemo} from 'react'
import {ModalBodyContext, signatureSeparator, translationSeparator} from '../../utils/constants'
import {stripSignature} from '../../utils/inbox_translator'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conversations_2')

interface TranslationControlsProps {
  inboxSettingsFeature: boolean
  signature: string
}

const TranslationControls = (props: TranslationControlsProps) => {
  // @ts-expect-error
  const languages = useRef(ENV?.inbox_translation_languages ?? [])
  const [language, setLanguage] = useState('English')
  const [includeTranslation, setIncludeTranslation] = useState(false)
  const {
    setMessagePosition,
    messagePosition,
    // @ts-expect-error
    translationTargetLanguage,
    setTranslationTargetLanguage,
    translateBody,
    // @ts-expect-error
    translateBodyWith,
    body,
    setBody,
  } = useContext(ModalBodyContext)

  // If we have a message position, the message has been translated.
  const primary = useMemo(() => {
    if (messagePosition === null) {
      return null
    }

    return messagePosition === 'primary'
  }, [messagePosition])

  const translated = useMemo(() => {
    return messagePosition !== null && body.includes(translationSeparator)
  }, [messagePosition, body])

  // @ts-expect-error
  const handleSelect = (e, {id, value}) => {
    setLanguage(value)
    setTranslationTargetLanguage(id)

    // If this has already been translated, we need to change the language.
    if (translated) {
      let newBody = body
      if (props.inboxSettingsFeature && props.signature !== '') {
        newBody = stripSignature(newBody)
      }
      newBody = newBody.split(translationSeparator)[primary ? 1 : 0]
      translateBodyWith(primary, newBody, {tgtLang: id})
    }
  }

  /**
   * Handle placing translated message in primary or secondary position
   * */
  // @ts-expect-error
  const handleChange = isPrimary => {
    // If not already translated, translate the body.
    setMessagePosition(isPrimary ? 'primary' : 'secondary')
    if (!translated) {
      translateBody(isPrimary)
      return
    }

    // @ts-expect-error
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

  // @ts-expect-error
  const handleIncludeTranslation = shouldInclude => setIncludeTranslation(shouldInclude)

  useEffect(() => {
    if (!includeTranslation && translated) {
      setMessagePosition(null)
      // @ts-expect-error
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
    }
  }, [
    includeTranslation,
    setMessagePosition,
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
              // @ts-expect-error
              onChange={handleSelect}
              width="360px"
            >
              {/* @ts-expect-error */}
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
