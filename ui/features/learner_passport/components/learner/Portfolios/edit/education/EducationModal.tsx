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
import type {EducationData} from '../../../../types'
import {formatDate} from '../../../../shared/utils'
import StatePicker from '../../../../shared/StatePicker'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'

interface EducationModalProps {
  education: EducationData | null
  open: boolean
  onDismiss: () => void
  onSave: (education: EducationData) => void
}

const EducationModal = ({education, open, onDismiss, onSave}: EducationModalProps) => {
  const [id, setId] = useState(education?.id ?? uid('edu', 2))
  const [institution, setInstitution] = useState(education?.institution ?? '')
  const [city, setCity] = useState(education?.city ?? '')
  const [state, setState] = useState(education?.state ?? '')
  const [title, setTitle] = useState(education?.title ?? '')
  const [from_date, setFromDate] = useState(education?.from_date ?? '')
  const [to_date, setToDate] = useState(education?.to_date ?? '')
  const [gpa, setGpa] = useState(education?.gpa ?? '')

  useEffect(() => {
    if (education) {
      setId(education.id)
      setInstitution(education.institution)
      setCity(education.city)
      setState(education.state)
      setTitle(education.title)
      setFromDate(education.from_date)
      setToDate(education.to_date)
      setGpa(education.gpa)
    } else {
      setId(uid('edu', 2))
      setInstitution('')
      setCity('')
      setState('')
      setTitle('')
      setFromDate('')
      setToDate('')
      setGpa('')
    }
  }, [education])

  const isValid = useCallback(() => {
    return institution && city && state && from_date && to_date
  }, [city, from_date, institution, state, to_date])

  const handleDismiss = useCallback(() => {
    onDismiss()
  }, [onDismiss])

  const handleSave = useCallback(() => {
    if (!isValid()) return
    onSave({
      id,
      institution: institution.trim(),
      city: city.trim(),
      state: state.trim(),
      title: title.trim(),
      from_date,
      to_date,
      gpa: gpa.trim(),
    })
  }, [city, from_date, gpa, id, institution, isValid, onSave, state, title, to_date])

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

  const renderBodyContents = () => {
    return (
      <>
        <View as="div" margin="small 0">
          <TextInput
            name="education[institution]"
            renderLabel="Institution name"
            value={institution}
            onChange={(_e, value) => setInstitution(value)}
          />
        </View>
        <Flex gap="small">
          <Flex.Item margin="small 0" shouldGrow={true}>
            <TextInput
              name="education[city]"
              renderLabel="City"
              value={city}
              onChange={(_e, value) => setCity(value)}
            />
          </Flex.Item>
          <Flex.Item shouldGrow={true}>
            <StatePicker state={state} onChange={setState} />
          </Flex.Item>
        </Flex>
        <Flex gap="small">
          <Flex.Item margin="small 0" shouldGrow={true}>
            <TextInput
              name="education[title]"
              renderLabel="Degree or certification (optional)"
              value={title}
              onChange={(_e, value) => setTitle(value)}
            />
          </Flex.Item>
          <Flex.Item shouldGrow={true}>
            <TextInput
              name="education[gpa]"
              renderLabel="GPA (optional)"
              value={gpa}
              onChange={(_e, value) => setGpa(value)}
            />
          </Flex.Item>
        </Flex>
        <View as="div" margin="small 0">
          <FormFieldGroup
            description="Time Period"
            colSpacing="small"
            layout="columns"
            vAlign="top"
          >
            <CanvasDateInput
              renderLabel={<Text weight="normal">From</Text>}
              formatDate={formatDate}
              interaction="enabled"
              selectedDate={from_date}
              onSelectedDateChange={handleSetFromDate}
            />
            <CanvasDateInput
              renderLabel={<Text weight="normal">To</Text>}
              formatDate={formatDate}
              interaction="enabled"
              selectedDate={to_date}
              onSelectedDateChange={handleSetToDate}
            />
          </FormFieldGroup>
        </View>
      </>
    )
  }

  return (
    <Modal open={open} size="auto" label="Edit Cover Image" onDismiss={onDismiss}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleDismiss}
          screenReaderLabel="Close"
        />
        <Heading>{education ? 'Edit Education' : 'Add Education'}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small 0">
          {renderBodyContents()}
        </View>
      </Modal.Body>
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

export default EducationModal
