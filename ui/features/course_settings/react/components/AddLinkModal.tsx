/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useState, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('course_navigation_settings')

const MAX_URL_LENGTH = 2048
const MAX_TEXT_LENGTH = 50

// Returns an error string if invalid
function validateUrl(str: string): string | undefined {
  if (str.length > MAX_URL_LENGTH) {
    return I18n.t('URL is too long (maximum %{max} characters)', {max: MAX_URL_LENGTH})
  }

  try {
    const url = new URL(str)
    if (url.protocol !== 'http:' && url.protocol !== 'https:') {
      return I18n.t('Please enter a valid URL beginning with https:// or http://')
    }
    return undefined
  } catch (_) {
    return I18n.t('Please enter a valid URL beginning with https:// or http://')
  }
}

// Returns an error string if invalid
function validateText(normalizedText: string): string | undefined {
  if (normalizedText.length === 0 || normalizedText.length > MAX_TEXT_LENGTH) {
    return I18n.t('Please enter text between 1 and %{max} characters long', {max: MAX_TEXT_LENGTH})
  }
}

export interface AddLinkModalProps {
  onDismiss: () => void
  onAdd: (link: {text: string; url: string}) => void
}

function normalize({text, url}: {text: string; url: string}): {text: string; url: string} {
  return {text: text.trim(), url: url.trim()}
}

function textLengthHintText(normalizedText: string): string {
  const charsRemaining = MAX_TEXT_LENGTH - normalizedText.length
  if (charsRemaining > 1) {
    return I18n.t('%{charsRemaining} characters remaining', {charsRemaining})
  } else if (charsRemaining === 1) {
    return I18n.t('%{charsRemaining} character remaining', {charsRemaining})
  } else if (charsRemaining === 0) {
    return I18n.t('0 characters remaining')
  } else {
    return I18n.t('%{charsTooMany} characters too many', {charsTooMany: -charsRemaining})
  }
}

function makeMessages({
  hint,
  error,
  errorEnabled,
}: {
  hint: string
  error: string | undefined
  errorEnabled: boolean
}): FormMessage[] {
  const result: FormMessage[] = [{type: 'hint', text: hint}]
  if (errorEnabled && error) {
    result.unshift({type: 'error', text: error})
  }
  return result
}

export const AddLinkModal = ({onDismiss, onAdd}: AddLinkModalProps) => {
  const [text, setText] = useState('')
  const [url, setUrl] = useState('https://')

  // We only show errors after field has been blurred
  const [hasBlurred, setHasBlurred] = useState({text: false, url: false})
  const textInputRef = useRef<HTMLInputElement | null>(null)
  const urlInputRef = useRef<HTMLInputElement | null>(null)

  const normalized = normalize({text, url})
  const urlError = validateUrl(normalized.url)
  const textError = validateText(normalized.text)

  const handleAdd = () => {
    // Mark all fields as blurred to show any errors
    setHasBlurred({text: true, url: true})

    // Focus on first field with error
    if (textError) {
      textInputRef.current?.focus()
      return
    }

    if (urlError) {
      urlInputRef.current?.focus()
      return
    }

    // All valid, proceed
    onAdd(normalized)
    onDismiss()
    setText('')
    setUrl('https://')
    setHasBlurred({text: false, url: false})
  }

  return (
    <Modal
      label={I18n.t('Add Link')}
      size="small"
      open={true}
      onDismiss={onDismiss}
      shouldCloseOnDocumentClick={false}
      closeButtonElementRef={el => {
        el?.setAttribute('data-pendo', 'add-link-modal-close-button')
      }}
    >
      <Modal.Body overflow="scroll">
        <View height="25rem" as="div">
          <View as="div" margin="none none medium">
            <TextInput
              inputRef={ref => (textInputRef.current = ref)}
              renderLabel={I18n.t('Text')}
              isRequired={true}
              value={text}
              onChange={(_e, value) => setText(value)}
              onBlur={() => {
                setHasBlurred(prev => ({...prev, text: true}))
              }}
              messages={makeMessages({
                hint: I18n.t('This is the text that will show up in all placements.'),
                error: textError,
                errorEnabled: hasBlurred.text,
              })}
            />
            <View as="div" margin="x-small none none">
              <Text
                size="small"
                color={normalized.text.length > MAX_TEXT_LENGTH ? 'danger' : 'secondary'}
              >
                {textLengthHintText(normalized.text)}
              </Text>
            </View>
          </View>
          <View as="div" margin="none none medium">
            <TextInput
              inputRef={ref => {
                if (ref) urlInputRef.current = ref
              }}
              renderLabel={I18n.t('Link')}
              isRequired={true}
              value={url}
              onChange={(_e, value) => {
                setUrl(value)
              }}
              onBlur={() => {
                setHasBlurred(prev => ({...prev, url: true}))
              }}
              messages={makeMessages({
                hint: I18n.t('This can be an external link or a Canvas URL.'),
                error: urlError,
                errorEnabled: hasBlurred.url,
              })}
            />
          </View>
          <View as="div">
            <Text weight="bold">{I18n.t('Opening Behavior')}</Text>
            <View as="div" margin="x-small none none">
              <Text>{I18n.t('This link will open in a new tab.')}</Text>
            </View>
          </View>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss} data-pendo="add-link-modal-button-cancel">
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          margin="none none none small"
          data-pendo="add-link-modal-button-add"
          onClick={handleAdd}
        >
          {I18n.t('Add')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
