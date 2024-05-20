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

import React, {useCallback, useEffect, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {uid} from '@instructure/uid'
import type {ExperienceData} from '../../../../types'
import {formatDate} from '../../../../shared/utils'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
// import CanvasRce from '@canvas/rce/react/CanvasRce'
import RichTextEdit from '../../../../shared/RichTextEdit'

interface ExperienceModalProps {
  experience: ExperienceData | null
  open: boolean
  onDismiss: () => void
  onSave: (experience: ExperienceData) => void
}

const ExperienceModal = ({experience, open, onDismiss, onSave}: ExperienceModalProps) => {
  const [id, setId] = useState(experience?.id ?? uid('edu', 2))
  const [where, setWhere] = useState(experience?.where ?? '')
  const [title, setTitle] = useState(experience?.title ?? '')
  const [from_date, setFromDate] = useState(experience?.from_date ?? '')
  const [to_date, setToDate] = useState(experience?.to_date ?? '')
  const [description, setDescription] = useState(experience?.description ?? '')

  const clear = () => {
    setId(uid('edu', 2))
    setWhere('')
    setTitle('')
    setFromDate('')
    setToDate('')
    setDescription('')
  }

  useEffect(() => {
    if (experience) {
      setId(experience.id)
      setWhere(experience.where.trim())
      setTitle(experience.title.trim())
      setFromDate(experience.from_date)
      setToDate(experience.to_date)
      setDescription(experience.description.trim())
    } else {
      clear()
    }
  }, [experience])

  const isValid = useCallback(() => {
    return title?.trim() && where?.trim() && from_date && to_date
  }, [from_date, title, to_date, where])

  const handleDismiss = useCallback(() => {
    onDismiss()
  }, [onDismiss])

  const handleSave = useCallback(() => {
    if (!isValid()) return
    onSave({
      id,
      where,
      title,
      from_date,
      to_date,
      description,
    })
  }, [description, from_date, id, isValid, onSave, title, to_date, where])

  const handleSetFromDate = useCallback(
    (date: Date | null, _dateInputType: 'pick' | 'other' | 'error') => {
      if (date) {
        setFromDate(date.toISOString())
      } else {
        setFromDate('')
      }
    },
    []
  )

  const handleSetToDate = useCallback(
    (date: Date | null, _dateInputType: 'pick' | 'other' | 'error') => {
      if (date) {
        setToDate(date.toISOString())
      } else {
        setToDate('')
      }
    },
    []
  )

  const handleDescriptionChange = useCallback((content: string) => {
    setDescription(content)
  }, [])

  const renderBodyContents = () => {
    return (
      <View as="div" maxWidth="45rem">
        <View as="div" margin="0 0 medium 0">
          <TextInput
            renderLabel="Title"
            placeholder="Enter title"
            value={title}
            onChange={(_e, value) => setTitle(value)}
          />
        </View>
        <View as="div" margin="0 0 medium 0">
          <TextInput
            renderLabel="Organization name"
            placeholder="Enter organization name"
            value={where}
            onChange={(_e, value) => setWhere(value)}
          />
        </View>
        <View as="div" margin="0 0 small 0">
          <RichTextEdit
            id="experience_description"
            label="Description"
            content={description}
            onContentChange={handleDescriptionChange}
          />
        </View>
        <View as="div" margin="0 0 0 0">
          <FormFieldGroup
            description="Time Period"
            colSpacing="medium"
            layout="columns"
            vAlign="top"
          >
            <Flex gap="small">
              <Flex.Item shouldGrow={true}>
                <CanvasDateInput
                  renderLabel={<Text weight="normal">From</Text>}
                  placeholder="Select"
                  formatDate={formatDate}
                  interaction="enabled"
                  width="20rem"
                  selectedDate={from_date}
                  onSelectedDateChange={handleSetFromDate}
                />
              </Flex.Item>
              <Flex.Item shouldGrow={true}>
                <CanvasDateInput
                  renderLabel={<Text weight="normal">To</Text>}
                  placeholder="Select"
                  formatDate={formatDate}
                  interaction="enabled"
                  width="20rem"
                  selectedDate={to_date}
                  onSelectedDateChange={handleSetToDate}
                />
              </Flex.Item>
            </Flex>
          </FormFieldGroup>
        </View>
      </View>
    )
  }

  return (
    <Modal
      open={open}
      shouldCloseOnDocumentClick={false}
      size="auto"
      label="Edit Cover Image"
      onDismiss={onDismiss}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleDismiss}
          screenReaderLabel="Close"
        />
        <Heading>{experience ? 'Edit Experience' : 'Add Experience'}</Heading>
      </Modal.Header>
      <Modal.Body>{renderBodyContents()}</Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={handleDismiss}>
          Cancel
        </Button>
        <Tooltip
          renderTip="You must complete the form before saving."
          on={isValid() ? [] : ['click', 'hover', 'focus']}
        >
          <Button color="primary" margin="0 0 0 small" onClick={handleSave}>
            Save
          </Button>
        </Tooltip>
      </Modal.Footer>
    </Modal>
  )
}

export default ExperienceModal
