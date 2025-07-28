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

import React, {useCallback, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {TextInput} from '@instructure/ui-text-input'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type LinkModalProps = {
  open: boolean
  text?: string
  url?: string
  onClose: () => void
  onSubmit: (text: string, url: string) => void
}

const LinkModal = ({open, text = '', url = '', onClose, onSubmit}: LinkModalProps) => {
  const [currText, setCurrText] = useState(text)
  const [currUrl, setCurrUrl] = useState(url)

  const handleTextChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setCurrText(e.target.value)
  }, [])

  const handleUrlChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setCurrUrl(e.target.value)
  }, [])

  const handleSubmit = useCallback(() => {
    onSubmit(currText, currUrl)
    onClose()
  }, [onSubmit, onClose, currText, currUrl])

  return (
    <Modal open={open} onDismiss={onClose} label="Link" size="medium">
      <Modal.Header>
        <Heading level="h2">{I18n.t('Select an Icon')}</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body padding="medium">
        <TextInput
          renderLabel={I18n.t('Text')}
          placeholder={I18n.t('Text')}
          value={currText}
          onChange={handleTextChange}
        />
        <TextInput
          renderLabel={I18n.t('URL')}
          placeholder={I18n.t('URL')}
          value={currUrl}
          onChange={handleUrlChange}
        />
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" onClick={handleSubmit} margin="0 0 0 small">
          {I18n.t('Submit')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {LinkModal}
