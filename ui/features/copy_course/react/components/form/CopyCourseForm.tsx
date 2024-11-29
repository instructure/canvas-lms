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

import React, {type Dispatch, useState, useReducer} from 'react'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {CommonMigratorControls, parseDateToISOString} from '@canvas/content-migrations'
import {CreateCourseLabel} from './formComponents/CreateCourseLabel'
import {ConfiguredDateInput} from './formComponents/ConfiguredDateInput'
import {ConfiguredTextInput} from './formComponents/ConfiguredTextInput'
import {ConfiguredSelectInput} from './formComponents/ConfiguredSelectInput'
import type {Course} from '../../../../../api'
import type {CopyCourseFormSubmitData, Term} from '../../types'
import {CreateCourseInProgressLabel} from './formComponents/CreateCourseInProgressLabel'
import type {submitMigrationFormData} from '@canvas/content-migrations/react/CommonMigratorControls/types'

type InvalidFormElements = {
  newCourseStartDate?: string
  newCourseEndDate?: string
}

type InvalidForm = {
  elements: InvalidFormElements
  isInvalid: boolean
}

const I18n = useI18nScope('content_copy_redesign')
const dateOrNull = (dateString: string | undefined) => (dateString ? new Date(dateString) : null)
const defaultInvalidForm = {elements: {}, isInvalid: false}

const validationReducer = (
  state: InvalidForm,
  action: {type: string; payload?: InvalidFormElements}
) => {
  switch (action.type) {
    case 'invalidate':
      return {
        elements: {
          ...state.elements,
          ...action.payload,
        },
        isInvalid: true,
      }
    case 'clear':
      return {
        elements: {},
        isInvalid: false,
      }
    default:
      return state
  }
}

export const CopyCourseForm = ({
  course,
  terms,
  timeZone,
  canImportAsNewQuizzes,
  isSubmitting,
  onSubmit,
  onCancel,
}: {
  course: Course
  terms: Term[]
  timeZone?: string
  canImportAsNewQuizzes: boolean
  isSubmitting: boolean
  onSubmit: (data: CopyCourseFormSubmitData) => void
  onCancel: () => void
}) => {
  const [courseName, setCourseName] = useState<string>(course.name)
  const [courseCode, setCourseCode] = useState<string>(course?.course_code || '')
  const [newCourseStartDate, setNewCourseStartDate] = useState<Date | null>(
    dateOrNull(course?.start_at)
  )
  const [newCourseEndDate, setNewCourseEndDate] = useState<Date | null>(dateOrNull(course?.end_at))
  const [selectedTerm, setSelectedTerm] = useState<Term | null>(terms[0] || null)
  const [invalidForm, dispatchForm] = useReducer(validationReducer, defaultInvalidForm)

  const validateCourseDates = () => {
    if (newCourseStartDate && newCourseEndDate && newCourseStartDate > newCourseEndDate) {
      dispatchForm({
        type: 'invalidate',
        payload: {
          newCourseStartDate: I18n.t('Start date must be before end date'),
          newCourseEndDate: I18n.t('End date must be after start date'),
        },
      })
      return false
    }

    return true
  }

  const handleSubmit = (formData: submitMigrationFormData, _: File | undefined) => {
    dispatchForm({type: 'clear'})
    if (!validateCourseDates()) return

    onSubmit({
      courseName,
      courseCode,
      newCourseStartDate,
      newCourseEndDate,
      selectedTerm,
      ...formData,
    })
  }

  const handleSelectTerm = (selectedId: string | null) => {
    if (!selectedId) return
    const term = terms.find(({id}) => id === selectedId)
    term && setSelectedTerm(term)
  }

  const isoNewCourseStartDate = parseDateToISOString(newCourseStartDate)
  const isoNewCourseEndDate = parseDateToISOString(newCourseEndDate)
  const canImportBpSettings = course.blueprint || false
  const invalidNewCourseEndDateMessage = invalidForm.elements.newCourseEndDate
  const invalidNewCourseStartDateMessage = invalidForm.elements.newCourseStartDate

  return (
    <View as="div">
      <Heading level="h1" margin="0 0 small">
        {I18n.t('Copy course')}
      </Heading>
      <Text size="large">{I18n.t('Please enter the details for the new course.')}</Text>
      <View as="div" margin="large none none none" width="100%" maxWidth="28.75rem">
        <View as="div" margin="medium none none none">
          <ConfiguredTextInput
            label={I18n.t('Name')}
            inputValue={courseName}
            onChange={setCourseName}
            disabled={isSubmitting}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredTextInput
            label={I18n.t('Course code')}
            inputValue={courseCode}
            onChange={setCourseCode}
            disabled={isSubmitting}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredDateInput
            selectedDate={isoNewCourseStartDate}
            onSelectedDateChange={setNewCourseStartDate}
            placeholder={I18n.t('Select start date')}
            renderLabelText={I18n.t('Start date')}
            renderScreenReaderLabelText={I18n.t('Select a new beginning date')}
            timeZone={timeZone}
            disabled={isSubmitting}
            errorMessage={invalidNewCourseStartDateMessage}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredDateInput
            selectedDate={isoNewCourseEndDate}
            onSelectedDateChange={setNewCourseEndDate}
            placeholder={I18n.t('Select end date')}
            renderLabelText={I18n.t('End date')}
            renderScreenReaderLabelText={I18n.t('Select a new end date')}
            timeZone={timeZone}
            disabled={isSubmitting}
            errorMessage={invalidNewCourseEndDateMessage}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredSelectInput
            label={I18n.t('Term')}
            defaultInputValue={terms[0]?.name}
            options={terms}
            onSelect={handleSelectTerm}
            disabled={isSubmitting}
          />
        </View>
      </View>
      <CommonMigratorControls
        canAdjustDates={true}
        canSelectContent={true}
        canImportBPSettings={canImportBpSettings}
        canImportAsNewQuizzes={canImportAsNewQuizzes}
        newStartDate={isoNewCourseStartDate}
        newEndDate={isoNewCourseEndDate}
        oldStartDate={isoNewCourseStartDate}
        oldEndDate={isoNewCourseEndDate}
        fileUploadProgress={null}
        isSubmitting={isSubmitting}
        onCancel={onCancel}
        onSubmit={handleSubmit}
        SubmitLabel={CreateCourseLabel}
        SubmittingLabel={CreateCourseInProgressLabel}
      />
    </View>
  )
}
