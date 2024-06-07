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
import {Flex} from '@instructure/ui-flex'
import {type FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {validateSVG} from '../../../../utils'

type LinkModalProps = {
  open: boolean
  svg?: string
  onClose: () => void
  onSubmit: (svg: string) => void
}

const SVGImageModal = ({open, svg = '', onClose, onSubmit}: LinkModalProps) => {
  const [currSvg, setCurrSvg] = useState(svg)
  const [messages, setMessages] = useState<FormMessage[]>([])
  const previewRef = useRef<HTMLDivElement | null>(null)
  const textareaRef = useRef<HTMLTextAreaElement | null>(null)

  const handleSvgChange = useCallback((e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = e.target.value
    setCurrSvg(value)
    if (value.length === 0 || validateSVG(value)) {
      setMessages([])
    } else {
      setMessages([{text: 'Invalid SVG', type: 'error'}])
    }
  }, [])

  const handleSubmit = useCallback(() => {
    onSubmit(currSvg)
    onClose()
  }, [onSubmit, onClose, currSvg])

  return (
    <Modal open={open} onDismiss={onClose} label="Link" size="medium">
      <Modal.Header>
        <Heading level="h2">SVG Text</Heading>
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body padding="medium">
        <Flex direction="column" gap="small">
          <div
            style={{
              display: 'flex',
              minHeight: '1rem',
              boxSizing: 'border-box',
              padding: '4px',
            }}
            ref={previewRef}
            dangerouslySetInnerHTML={{__html: currSvg}}
          />
          <TextArea
            textareaRef={el => (textareaRef.current = el)}
            label={<ScreenReaderContent>Enter SVG text</ScreenReaderContent>}
            value={currSvg}
            onChange={handleSvgChange}
            messages={messages}
            placeholder="Enter SVG"
            resize="none"
          />
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button color="primary" onClick={handleSubmit} margin="0 0 0 small">
          Submit
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {SVGImageModal}
