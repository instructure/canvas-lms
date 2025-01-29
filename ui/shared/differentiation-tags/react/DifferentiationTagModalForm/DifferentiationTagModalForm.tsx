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

import React, {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {DifferentiationTagSet, ModalMode} from '../types'

const I18n = createI18nScope('differentiation_tags')

export type DifferentiationTagModalFormProps = {
  isOpen: boolean
  onClose: () => void
  differentiationTagSet?: DifferentiationTagSet
  mode: ModalMode
}

const modeConfig = {
  create: {
    title: I18n.t('Create Tag'),
    submitLabel: I18n.t('Save'),
    showTagSetSelector: true,
    showTagVariantRadioButtons: false,
  },
  edit: {
    title: I18n.t('Edit Tag'),
    submitLabel: I18n.t('Update'),
    showTagSetSelector: false,
    showTagVariantRadioButtons: true,
  },
}

interface ModalBodyProps {
  mode: ModalMode
  differentiationTagSet?: DifferentiationTagSet
}

const ModalBody = ({mode, differentiationTagSet}: ModalBodyProps) => {
  const {showTagSetSelector, showTagVariantRadioButtons} = modeConfig[mode]

  return (
    <>
      <Alert variant="info" margin="small none small none">
        {I18n.t('Tags are not visible to students.')}
      </Alert>

      {showTagVariantRadioButtons && (
        <div style={{marginTop: '1rem'}}>
          <div>Future radio button for single vs tag with variants</div>
        </div>
      )}

      <div style={{marginTop: '1rem'}}>
        <Heading level="h4">{I18n.t('Tag Name*')}</Heading>
        <div>Future Tag name input here</div>
      </div>

      {showTagSetSelector && (
        <div style={{marginTop: '1rem'}}>
          <Heading level="h4">{I18n.t('Tag Set*')}</Heading>
          <div>Future Tag Set Selector here</div>
        </div>
      )}

      {/* This is 100% temporary to show data pulled for use in the modal */}
      {mode === 'edit' && differentiationTagSet?.groups && (
        <div style={{marginTop: '1rem'}}>
          <Heading level="h4">{I18n.t('Groups')}</Heading>
          <ul>
            {differentiationTagSet.groups.map(group => (
              <li key={group.id}>
                {group.name} {I18n.t('(ID: %{id})', {id: group.id})}
              </li>
            ))}
          </ul>
        </div>
      )}
    </>
  )
}

export default function DifferentiationTagModalForm(props: DifferentiationTagModalFormProps) {
  const {isOpen, onClose, mode} = props
  const [isSubmitting, setIsSubmitting] = useState(false)
  const config = modeConfig[mode]

  const differentiationTagSet = mode === 'edit' ? props.differentiationTagSet : undefined

  const handleFormSubmit = async () => {
    if (isSubmitting) return

    console.log('Temporary submit logic/output')

    try {
      setIsSubmitting(true)
      //   TODO REMOVE IN NEXT PS, TEMPORARY TO SIMULATE REQUEST
      await new Promise(resolve => setTimeout(resolve, 1000))
      onClose()
    } catch (error) {
      console.error(I18n.t('Submission error:'), error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <Modal open={isOpen} onDismiss={onClose} size="medium" label={config.title}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{config.title}</Heading>
      </Modal.Header>

      <Modal.Body>
        <Flex as="div" margin="medium 0" direction="column">
          <ModalBody mode={mode} differentiationTagSet={differentiationTagSet} />
        </Flex>
      </Modal.Body>

      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          onClick={handleFormSubmit}
          color="primary"
          interaction={isSubmitting ? 'disabled' : 'enabled'}
        >
          {isSubmitting ? I18n.t('Submitting...') : config.submitLabel}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
