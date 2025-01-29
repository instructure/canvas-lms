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
import React, {useCallback, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {type FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {useScope as createI18nScope} from '@canvas/i18n'
import {type BlockTemplate, type TemplateType} from '../../types'

const I18n = createI18nScope('block-editor')

type SaveMode = 'save' | 'edit'

export type OnSaveTemplateCallback = (
  template: Partial<BlockTemplate>,
  globalTemplate: boolean,
) => void

type EditTemplateModalProps = {
  mode: SaveMode
  template?: Partial<BlockTemplate>
  templateType: TemplateType
  isGlobalEditor: boolean
  onDismiss: () => void
  onSave: OnSaveTemplateCallback
}
const EditTemplateModal = ({
  mode,
  template,
  templateType,
  isGlobalEditor,
  onDismiss,
  onSave,
}: EditTemplateModalProps) => {
  const [name, setName] = useState(template?.name || '')
  const [description, setDescription] = useState(template?.description || '')
  const [published, setPublished] = useState(template?.workflow_state === 'active')
  const [globalTemplate, setGlobalTemplate] = useState(false)
  const [nameErrorMsg, setNameErrorMsg] = useState<FormMessage[] | undefined>(undefined)
  const nameInputRef = useRef<HTMLInputElement | null>(null)

  const handleNameChange = useCallback((_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setName(value)
    if (value) {
      setNameErrorMsg(undefined)
    }
  }, [])
  const handleSave = useCallback(() => {
    if (!name) {
      setNameErrorMsg([
        {
          type: 'error',
          text: I18n.t('A template name is required'),
        },
      ])
      nameInputRef.current?.focus()
      return
    }
    const workflow_state = published ? 'active' : 'unpublished'
    onSave({name, description, workflow_state}, globalTemplate)
  }, [description, globalTemplate, name, onSave, published])

  const renderLabel = () => {
    return mode === 'save' ? I18n.t('Save as Template') : I18n.t('Edit Template')
  }

  return (
    <Modal as="div" label={renderLabel()} open={true} onDismiss={onDismiss}>
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
        <Heading level="h2">{renderLabel()}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="small">
          <TextInput
            elementRef={el => {
              nameInputRef.current = el as HTMLInputElement
            }}
            isRequired={true}
            messages={nameErrorMsg}
            renderLabel={I18n.t('Template Name')}
            placeholder={I18n.t('Enter template name')}
            value={name}
            onChange={handleNameChange}
            data-testid="edit-template-modal-text-input-template-name"
          />
          <TextArea
            label={I18n.t('Description')}
            height="3.6rem"
            placeholder={I18n.t('Enter template description')}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => {
              setDescription(e.target.value)
            }}
            data-testid="edit-template-modal-text-area-template-description"
          />
          <Checkbox
            label={I18n.t('Published')}
            checked={published}
            onChange={() => setPublished(!published)}
            id="edit-template-modal-checkbox-published"
          />
          {isGlobalEditor && templateType !== 'block' && (
            <Checkbox
              label={I18n.t('Global template')}
              checked={globalTemplate}
              onChange={() => setGlobalTemplate(!globalTemplate)}
              id="edit-template-modal-checkbox-global-template"
            />
          )}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end" gap="small">
          <Button data-testid="edit-template-modal-button-cancel" onClick={onDismiss}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            data-testid="edit-template-modal-button-save"
            color="primary"
            onClick={handleSave}
          >
            {I18n.t('Save')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
export {EditTemplateModal}
