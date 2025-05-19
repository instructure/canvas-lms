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

import React, {useMemo, useState, useReducer} from 'react'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
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
import {CreateCourseCancelLabel} from './formComponents/CreateCourseCancelLabel'

type InvalidFormElements = {
  newCourseStartDateErrorMsg?: string
  newCourseEndDateErrorMsg?: string
  courseNameErrorMsg?: string
  courseCodeErrorMsg?: string
}

type InvalidForm = {
  elements: InvalidFormElements
  isInvalid: boolean
}

const I18n = createI18nScope('content_copy_redesign')
const dateOrNull = (dateString: string | undefined) => (dateString ? new Date(dateString) : null)
const defaultInvalidForm = {elements: {}, isInvalid: false}

const validationReducer = (
  state: InvalidForm,
  action: {type: string; payload?: InvalidFormElements},
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
  userTimeZone,
  courseTimeZone,
  canImportAsNewQuizzes,
  isSubmitting,
  onSubmit,
  onCancel,
}: {
  course: Course
  terms: Term[]
  userTimeZone?: string
  courseTimeZone?: string
  canImportAsNewQuizzes: boolean
  isSubmitting: boolean
  onSubmit: (data: CopyCourseFormSubmitData) => void
  onCancel: () => void
}) => {
  const dateOrNullStartAt = useMemo(() => dateOrNull(course?.start_at), [course?.start_at])
  const dateOrNullEndAt = useMemo(() => dateOrNull(course?.end_at), [course?.end_at])
  const [courseName, setCourseName] = useState<string>(course.name)
  const [courseCode, setCourseCode] = useState<string>(course?.course_code || '')
  const [newCourseStartDate, setNewCourseStartDate] = useState<Date | null>(dateOrNullStartAt)
  const [newCourseEndDate, setNewCourseEndDate] = useState<Date | null>(dateOrNullEndAt)
  const [selectedTerm, setSelectedTerm] = useState<Term | null>(
    terms.find(term => term.id === course.enrollment_term_id.toString()) || null,
  )
  const [invalidForm, dispatchForm] = useReducer(validationReducer, defaultInvalidForm)
  const restrictEnrollmentsToCourseDates = course.restrict_enrollments_to_course_dates

  const validateCourseDates = () => {
    const validationErrors: InvalidFormElements = {}

    if (newCourseStartDate && newCourseEndDate && newCourseStartDate > newCourseEndDate) {
      validationErrors.newCourseStartDateErrorMsg = I18n.t('Start date must be before end date')
      validationErrors.newCourseEndDateErrorMsg = I18n.t('End date must be after start date')
    }

    if (courseName.length > 255) {
      validationErrors.courseNameErrorMsg = I18n.t('Course name must be 255 characters or less')
    }

    if (courseCode.length > 255) {
      validationErrors.courseCodeErrorMsg = I18n.t('Course code must be 255 characters or less')
    }

    if (Object.keys(validationErrors).length > 0) {
      dispatchForm({
        type: 'invalidate',
        payload: validationErrors,
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
      restrictEnrollmentsToCourseDates,
      courseTimeZone: course.time_zone,
      ...formData,
    })
  }

  const handleSelectTerm = (selectedId: string | null) => {
    if (!selectedId) return
    const term = terms.find(({id}) => id === selectedId)
    term && setSelectedTerm(term)
    if (!restrictEnrollmentsToCourseDates) {
      setNewCourseStartDate(term?.startAt ? new Date(term.startAt) : null)
      setNewCourseEndDate(term?.endAt ? new Date(term.endAt) : null)
    }
  }

  const newStartDateToParse = restrictEnrollmentsToCourseDates
    ? newCourseStartDate
    : selectedTerm?.startAt
  const newEndDateToParse = restrictEnrollmentsToCourseDates
    ? newCourseEndDate
    : selectedTerm?.endAt
  const isoNewCourseStartDate = parseDateToISOString(newStartDateToParse)
  const isoNewCourseEndDate = parseDateToISOString(newEndDateToParse)

  const isoOldCourseStartDate = parseDateToISOString(dateOrNullStartAt)
  const isoOldCourseEndDate = parseDateToISOString(dateOrNullEndAt)

  const canImportBpSettings = course.blueprint || false
  const invalidNewCourseEndDateMessage = invalidForm.elements.newCourseEndDateErrorMsg
  const invalidNewCourseStartDateMessage = invalidForm.elements.newCourseStartDateErrorMsg
  const invalidCourseNameMessage = invalidForm.elements.courseNameErrorMsg
  const invalidCourseCodeMessage = invalidForm.elements.courseCodeErrorMsg
  const disableStartEndDateMessage = !restrictEnrollmentsToCourseDates
    ? I18n.t(
        'Term start and end dates cannot be modified here, only on the Term Details page under Admin.',
      )
    : null

  return (
    <View as="div">
      <Heading level="h1" margin="0 0 small">
        {I18n.t('Copy course')}
      </Heading>
      <Text size="large">{I18n.t('Please enter the details for the new course.')}</Text>
      <View as="div" margin="large none none none" width="100%" maxWidth="28.75rem">
        <View as="div" margin="medium none none none" data-testid="course-name">
          <ConfiguredTextInput
            label={I18n.t('Name')}
            inputValue={courseName}
            onChange={setCourseName}
            disabled={isSubmitting}
            errorMessage={invalidCourseNameMessage}
          />
        </View>
        <View as="div" margin="medium none none none" data-testid="course-code">
          <ConfiguredTextInput
            label={I18n.t('Course code')}
            inputValue={courseCode}
            onChange={setCourseCode}
            disabled={isSubmitting}
            errorMessage={invalidCourseCodeMessage}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredSelectInput
            label={I18n.t('Term')}
            defaultInputValue={selectedTerm?.name}
            options={terms}
            onSelect={handleSelectTerm}
            disabled={isSubmitting}
            searchable
          />
        </View>
        <View as="div" margin="medium none none none" data-testid="course-start-date">
          <ConfiguredDateInput
            selectedDate={isoNewCourseStartDate}
            onSelectedDateChange={setNewCourseStartDate}
            placeholder={I18n.t('Select start date')}
            renderLabelText={I18n.t('Start date')}
            renderScreenReaderLabelText={I18n.t('Select a new beginning date')}
            userTimeZone={userTimeZone}
            courseTimeZone={courseTimeZone}
            disabled={isSubmitting || !restrictEnrollmentsToCourseDates}
            errorMessage={invalidNewCourseStartDateMessage}
            infoMessage={disableStartEndDateMessage}
            dataTestId="course_start_date"
          />
        </View>
        <View as="div" margin="medium none none none" data-testid="course-end-date">
          <ConfiguredDateInput
            selectedDate={isoNewCourseEndDate}
            onSelectedDateChange={setNewCourseEndDate}
            placeholder={I18n.t('Select end date')}
            renderLabelText={I18n.t('End date')}
            renderScreenReaderLabelText={I18n.t('Select a new end date')}
            userTimeZone={userTimeZone}
            courseTimeZone={courseTimeZone}
            disabled={isSubmitting || !restrictEnrollmentsToCourseDates}
            errorMessage={invalidNewCourseEndDateMessage}
            infoMessage={disableStartEndDateMessage}
            dataTestId="course_end_date"
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
        oldStartDate={isoOldCourseStartDate}
        oldEndDate={isoOldCourseEndDate}
        fileUploadProgress={null}
        isSubmitting={isSubmitting}
        onCancel={onCancel}
        onSubmit={handleSubmit}
        SubmitLabel={CreateCourseLabel}
        SubmittingLabel={CreateCourseInProgressLabel}
        CancelLabel={CreateCourseCancelLabel}
      />
    </View>
  )
}
