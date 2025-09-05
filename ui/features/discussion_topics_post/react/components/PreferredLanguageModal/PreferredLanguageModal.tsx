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

import {useContext, useMemo, useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {useTranslationStore} from '../../hooks/useTranslationStore'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import CanvasMultiSelect from '@canvas/multi-select/react'
import {IconAiSolid} from '@instructure/ui-icons'
import {DiscussionManagerUtilityContext} from '../../utils/constants'
import {useTranslation} from '../../hooks/useTranslation'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('discussion_topics_post')

interface PreferredLanguageModalProps {
  discussionTopicId: string
}

const PreferredLanguageModal = ({discussionTopicId}: PreferredLanguageModalProps) => {
  const [selectedLanguage, setSelectedLanguage] = useState<string | null>(null)
  const [input, setInput] = useState('')
  const [messages, setMessages] = useState<FormMessage[]>([])

  // TODO: remove translationLanguages from context and move to zustand store
  const {translationLanguages}: any = useContext(DiscussionManagerUtilityContext)

  const modalOpen = useTranslationStore(state => state.modalOpen)
  const handleClose = useTranslationStore(state => state.closeModal)

  const {savePreferredLanguage, updateLoading, forceTranslate} = useTranslation()

  const handleSelect = (selectedArray: string[]) => {
    const id = selectedArray[0]
    const result = translationLanguages.current.find(({id: _id}: {id: string}) => _id === id)

    setInput(result.name)
    setSelectedLanguage(result.id)
    setMessages([])
  }

  const handleTranslate = async () => {
    if (!selectedLanguage || updateLoading) {
      setMessages([
        {
          type: 'error',
          text: I18n.t('Please select a language.'),
        },
      ])

      return
    }

    if (selectedLanguage) {
      await savePreferredLanguage(selectedLanguage, discussionTopicId)
    }

    forceTranslate(selectedLanguage)
    handleClose()
  }

  const filteredLanguages = useMemo(() => {
    if (!input) {
      return translationLanguages.current
    }

    return translationLanguages.current.filter(({name}: {name: string}) =>
      name.toLowerCase().startsWith(input.toLowerCase()),
    )
  }, [input, translationLanguages])

  return (
    <Modal
      as="form"
      open={modalOpen}
      size="medium"
      onDismiss={handleClose}
      label={I18n.t('Select a Language for Translation')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Select a Language for Translation')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0 0 medium 0">
          <Text>
            {I18n.t(
              'To translate text, please choose your preferred language. This will be used as the default for all future translations. You can change it later in the translation section, or from the individual entry translation menu. Once set, this prompt won’t appear again automatically.',
            )}
          </Text>
        </View>
        <View as="div">
          <CanvasMultiSelect
            label={I18n.t('Translate to')}
            onChange={handleSelect}
            inputValue={input}
            onInputChange={e => setInput(e.target.value)}
            messages={messages}
            placeholder={I18n.t('Select a language...')}
          >
            {filteredLanguages.map(({id, name}: {id: string; name: string}) => (
              <CanvasMultiSelect.Option
                key={id}
                id={id}
                value={id}
                label={name}
                isSelected={id === selectedLanguage}
              >
                {name}
              </CanvasMultiSelect.Option>
            ))}
          </CanvasMultiSelect>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="x-small">
          <Flex.Item>
            <Button onClick={handleClose} data-testid="close-preferred-translation-modal">
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
          <Flex.Item>
            <Button color="ai-primary" renderIcon={<IconAiSolid />} onClick={handleTranslate}>
              {I18n.t('Translate')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export {PreferredLanguageModal}
