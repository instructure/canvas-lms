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
import {RadioInput} from '@instructure/ui-radio-input'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {isInstuiButtonColor} from '../blocks/ButtonBlock/common'
import {ColorPicker} from '../../editor/ColorPicker'
import {FormFieldGroup} from '@instructure/ui-form-field'

export type ColorModalVariant = 'background' | 'button' | 'textcolor'
type ColorModalProps = {
  open: boolean
  color: string
  variant: ColorModalVariant
  onClose: () => void
  onSubmit: (color: string) => void
}

const ColorModal = ({open, color, variant, onClose, onSubmit}: ColorModalProps) => {
  const [currColor, setCurrColor] = useState(color)

  const handleColorChange = useCallback((newColor: string) => {
    setCurrColor(newColor)
  }, [])

  const handleButtonColorChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      handleColorChange(event.target.value)
    },
    [handleColorChange]
  )

  const handleSubmit = useCallback(() => {
    onSubmit(currColor)
  }, [onSubmit, currColor])

  const renderModalHeading = () => {
    switch (variant) {
      case 'textcolor':
        return <Heading level="h2">Select Text Color</Heading>
      case 'button':
        return <Heading level="h2">Select a Button Color</Heading>
      case 'background':
        return <Heading level="h2">Select a Background Color</Heading>
      default:
        return <Heading level="h2">Select a color</Heading>
    }
  }

  return (
    <Modal open={open} onDismiss={onClose} label="Link" size="small">
      <Modal.Header>
        {renderModalHeading()}
        <CloseButton placement="end" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body padding="medium">
        {variant === 'button' && (
          <View as="div" margin="0 0 small 0" borderWidth="0 0 small 0" padding="0 0 small 0">
            <FormFieldGroup description="Standard Button Colors">
              <Flex as="div" margin="small" gap="small" wrap="wrap">
                <RadioInput
                  value="primary"
                  label="Primary"
                  inline={true}
                  onChange={handleButtonColorChange}
                  checked={currColor === 'primary'}
                />
                <RadioInput
                  value="secondary"
                  label="Secondary"
                  inline={true}
                  onChange={handleButtonColorChange}
                  checked={currColor === 'secondary'}
                />
                <RadioInput
                  value="success"
                  label="Success"
                  inline={true}
                  onChange={handleButtonColorChange}
                  checked={currColor === 'success'}
                />
                <RadioInput
                  value="danger"
                  label="Danger"
                  inline={true}
                  onChange={handleButtonColorChange}
                  checked={currColor === 'danger'}
                />
                <RadioInput
                  value="primary-inverse"
                  label="Primary Inverse"
                  inline={true}
                  onChange={handleButtonColorChange}
                  checked={currColor === 'primary-inverse'}
                />
                <RadioInput
                  value="custom"
                  label="Custom"
                  inline={true}
                  onChange={handleButtonColorChange}
                  checked={!isInstuiButtonColor(currColor)}
                />
              </Flex>
            </FormFieldGroup>
          </View>
        )}

        <ColorPicker
          label="Enter a hex color value"
          onChange={handleColorChange}
          value={currColor}
          disabled={isInstuiButtonColor(currColor)}
        />
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button color="primary" onClick={handleSubmit} margin="0 0 0 small">
          Set Color
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {ColorModal}
