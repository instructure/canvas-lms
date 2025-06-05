/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {createRoot} from 'react-dom/client'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ChooseEditorModalProps, EditorPrefEnv, EditorTypes} from './types'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv'

declare const ENV: GlobalEnv & EditorPrefEnv

const I18n = createI18nScope('block-editor')

type EditorChoices = 'rce' | 'block_editor' | 'canvas_content_builder' | ''

const ChooseEditorModal = (props: ChooseEditorModalProps) => {
  const [isOpen, setIsOpen] = useState<boolean>(true)
  const [rememberMyChoice, setRememberMyChoice] = useState<boolean>(!!ENV.text_editor_preference)
  const [editorChoice, setEditorChoice] = useState<EditorChoices>(ENV.text_editor_preference || '')
  const [erroredForm, setErroredForm] = useState<boolean>(false)
  const close = () => {
    setIsOpen(false)
    props.onClose()
  }

  const validEditorChoice = () => {
    if (['rce', 'block_editor', 'canvas_content_builder'].includes(editorChoice)) {
      return true
    } else {
      setErroredForm(true)
      return false
    }
  }

  const submitEditorChoice = async () => {
    if (validEditorChoice()) {
      await doFetchApi({
        method: 'PUT',
        path: `/api/v1/users/self/text_editor_preference`,
        body: {text_editor_preference: rememberMyChoice ? editorChoice : ''},
      })
      props.createPageAction(editorChoice)
      close()
    }
  }

  return (
    <Modal
      label="New Way To Create"
      open={isOpen}
      onDismiss={close}
      size="small"
      themeOverride={{smallMaxWidth: '27.5rem'}}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <Heading>{I18n.t('New Way to Create')}</Heading>
        <CloseButton placement="end" onClick={close} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body>
        <Heading level="h3" margin="0 0 small 0">
          {I18n.t('Try the New Block Editor')}
        </Heading>
        <Text lineHeight="condensed">
          <div>
            {I18n.t(
              "We've introduced a new editor to give you more flexibility and power in content creation. Choose the editor that best suits your workflow.",
            )}
          </div>
        </Text>
        <View
          as="div"
          borderRadius="medium"
          borderWidth="small"
          padding="small"
          margin="small 0 medium 0"
        >
          <Flex gap="small" justifyItems="space-between">
            <Flex.Item shouldShrink={true}>
              <Text size="x-small" lineHeight="condensed">
                <div>
                  {I18n.t(
                    'Read about key features and discover what you can create using the Block Editor.',
                  )}
                </div>
              </Text>
            </Flex.Item>
            <Flex.Item>
              <Link
                href="https://productmarketing.instructuremedia.com/embed/464a6c68-1de4-4821-bc0c-08101a5bc819"
                target="_blank"
              >
                <IconExternalLinkLine />
              </Link>
            </Flex.Item>
          </Flex>
        </View>
        <SimpleSelect
          onChange={(_e: React.SyntheticEvent, data: {value?: string | undefined | number}) => {
            setErroredForm(false)
            setEditorChoice(data.value as EditorTypes)
          }}
          renderLabel={I18n.t('Select an Editor')}
          messages={erroredForm ? [{type: 'error', text: I18n.t('Please choose an editor')}] : []}
          placeholder={I18n.t('Select One')}
          defaultValue={editorChoice}
          data-testid="choose-an-editor-dropdown"
          required={true}
        >
          {props.editorFeature === 'block_editor' && (
            <SimpleSelect.Option id="block_editor" value="block_editor">
              {I18n.t('Try the Block Editor')}
            </SimpleSelect.Option>
          )}
          {props.editorFeature === 'canvas_content_builder' && (
            <SimpleSelect.Option id="canvas_content_builder" value="canvas_content_builder">
              {I18n.t('Try the Canvas Content Builder')}
            </SimpleSelect.Option>
          )}
          <SimpleSelect.Option id="rce" value="rce">
            {I18n.t('Use the RCE')}
          </SimpleSelect.Option>
        </SimpleSelect>
        <View as="div" padding="small 0 medium 0">
          <Checkbox
            checked={rememberMyChoice}
            onChange={() => {
              setRememberMyChoice(!rememberMyChoice)
            }}
            label={I18n.t('Remember my choice')}
            value="remember_my_choice"
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button margin="0 x-small 0 0" onClick={close}>
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" onClick={submitEditorChoice}>
          {I18n.t('Continue')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const renderChooseEditorModal = (e: React.SyntheticEvent, createPageAction: () => {}) => {
  if (e != null) {
    e.preventDefault()
  }
  const editorFeature = ENV.EDITOR_FEATURE

  const rootElement = document.querySelector('#choose-editor-mount-point')
  if (rootElement) {
    const root = createRoot(rootElement)
    const editorModal = (
      <ChooseEditorModal
        editorFeature={editorFeature}
        createPageAction={createPageAction}
        onClose={() => root.unmount()}
      />
    )
    root.render(editorModal)
    return editorModal
  }
}

export default renderChooseEditorModal
