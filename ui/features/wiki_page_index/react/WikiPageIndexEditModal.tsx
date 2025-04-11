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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useEffect, useState} from 'react'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import type {FormMessage} from '@instructure/ui-form-field'
import type {Root} from 'react-dom/client'
import {TITLE_MAX_LENGTH} from '@canvas/wiki/utils/constants'
import {checkForTitleConflict} from '@canvas/wiki/utils/titleConflicts'
import {debounce} from '@instructure/debounce'

const I18n = createI18nScope('wiki_pages')

const checkForTitleConflictDebounced = debounce(checkForTitleConflict, 500)

interface Model {
  get: (key: string) => string | null
  set: (key: string, value: string | null) => void
  save: () => Promise<void>
}

export interface WikiPageIndexEditModalProps {
  model: Model
  modalOpen: boolean
  closeModal: (id: string) => unknown[]
}

const WikiPageIndexEditModal = ({model, modalOpen, closeModal}: WikiPageIndexEditModalProps) => {
  const [name, setName] = useState(model?.get('title'))
  const [messages, setMessages] = useState<FormMessage[]>([])
  const [open, setOpen] = useState(modalOpen)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    setOpen(modalOpen)
    if (modalOpen) {
      setName(model?.get('title'))
      setMessages([])
      setSaving(false)
    }
  }, [model, modalOpen])

  const handleSubmit = async (e: React.SyntheticEvent<unknown, unknown>) => {
    e.preventDefault()
    const errors: FormMessage[] = validateFormFields()
    if (errors.length === 0) {
      model.set('title', name)
      setSaving(true)
      try {
        await model.save()
        handleClose(e)
      } catch {
        showFlashError(I18n.t('There was an error saving the page title'))()
      } finally {
        setSaving(false)
      }
      setSaving(false)
    } else {
      document.querySelector<HTMLElement>('#page-title-input')?.focus()
    }
  }

  const validateFormFields = () => {
    const errors: FormMessage[] = []

    if (name == null || name.trim() === '') {
      errors.push({
        type: 'newError',
        text: I18n.t('A title is required'),
      })
    } else if (name.length > TITLE_MAX_LENGTH) {
      errors.push({
        type: 'newError',
        text: I18n.t("Title can't exceed %{max} characters", {max: TITLE_MAX_LENGTH}),
      })
    }

    setMessages(errors)
    return errors
  }

  const handleClose = (e: React.SyntheticEvent<unknown, unknown>) => {
    e.preventDefault()
    if (saving) return
    const pageId = model.get('page_id')
    closeModal(`a#${pageId}-menu.al-trigger`)
    const focusTarget = document.querySelector<HTMLElement>(`a[id="${pageId}-menu"]`)
    focusTarget?.focus()
  }

  const onTitleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setName(e.target.value)
  }

  const onTitleBlur = () => {
    const errors = validateFormFields()

    if (errors.length === 0) {
      const currentPageId = model.get('page_id')
      if (name !== null)
        checkForTitleConflictDebounced(name, setMessages, currentPageId ?? undefined)
    }
  }

  return (
    <Modal
      id="wikiTitleEditModal"
      as="form"
      open={open}
      data-testid="wikiTitleEditModal"
      label={I18n.t('Edit Page')}
      size="medium"
      onDismiss={handleClose}
      onSubmit={handleSubmit}
    >
      <Modal.Header data-testid="wikiTitleEditModalHeader">
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
          disabled={saving}
        />
        <Heading>{I18n.t('Edit Page')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <TextInput
          id="page-title-input"
          data-testid="page-title-input"
          value={name || undefined}
          isRequired={true}
          disabled={saving}
          messages={messages}
          onChange={onTitleChange}
          onBlur={onTitleBlur}
          renderLabel={I18n.t('Title')}
        />
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={handleClose} margin="0 x-small 0 0" disabled={saving}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          color="primary"
          type="submit"
          onClick={handleSubmit}
          data-testid="save-button"
          disabled={saving}
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default function renderWikiPageIndexEditModal(
  root: Root,
  props: WikiPageIndexEditModalProps,
) {
  const titleComponent = <WikiPageIndexEditModal {...props} />
  root.render(titleComponent)
  return titleComponent
}
