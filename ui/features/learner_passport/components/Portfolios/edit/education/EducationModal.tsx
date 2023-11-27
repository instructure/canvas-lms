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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {uid} from '@instructure/uid'
import type {EducationData} from '../../../types'
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
    console.log('>>>', education)
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

  const formatDate = useCallback((date: Date) => {
    return new Intl.DateTimeFormat(ENV.LOCALE || 'en', {month: 'short', year: 'numeric'}).format(
      date
    )
  }, [])

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
      institution,
      city,
      state,
      title,
      from_date,
      to_date,
      gpa,
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

  const handleChangeCity = useCallback((_e, value) => {
    setCity(value)
  }, [])

  const renderStates = () => {
    const states: Record<string, string> = {
      '--': '',
      Alabama: 'AL',
      Alaska: 'AK',
      Arizona: 'AZ',
      Arkansas: 'AR',
      California: 'CA',
      Colorado: 'CO',
      Connecticut: 'CT',
      Delaware: 'DE',
      Florida: 'FL',
      Georgia: 'GA',
      Hawaii: 'HI',
      Idaho: 'ID',
      Illinois: 'IL',
      Indiana: 'IN',
      Iowa: 'IA',
      Kansas: 'KS',
      Kentucky: 'KY',
      Louisiana: 'LA',
      Maine: 'ME',
      Maryland: 'MD',
      Massachusetts: 'MA',
      Michigan: 'MI',
      Minnesota: 'MN',
      Mississippi: 'MS',
      Missouri: 'MO',
      Montana: 'MT',
      Nebraska: 'NE',
      Nevada: 'NV',
      'New Hampshire': 'NH',
      'New Jersey': 'NJ',
      'New Mexico': 'NM',
      'New York': 'NY',
      'North Carolina': 'NC',
      'North Dakota': 'ND',
      Ohio: 'OH',
      Oklahoma: 'OK',
      Oregon: 'OR',
      Pennsylvania: 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      Tennessee: 'TN',
      Texas: 'TX',
      Utah: 'UT',
      Vermont: 'VT',
      Virginia: 'VA',
      Washington: 'WA',
      'West Virginia': 'WV',
      Wisconsin: 'WI',
      Wyoming: 'WY',
    }
    return Object.keys(states).map(st => (
      <SimpleSelect.Option id={st} key={st} value={states[st]}>
        {st}
      </SimpleSelect.Option>
    ))
  }

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
              onChange={handleChangeCity}
            />
          </Flex.Item>
          <Flex.Item shouldGrow={true}>
            <SimpleSelect
              name="education[state]"
              renderLabel="State"
              value={state}
              onChange={(_e, data) => setState(data.value as string)}
            >
              {renderStates()}
            </SimpleSelect>
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
