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

import React, {type Dispatch, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {CommonMigratorControls, parseDateToISOString} from '@canvas/content-migrations'
import {CreateCourseLabel} from './CreateCourseLabel'
import {ConfiguredDateInput} from './ConfiguredDateInput'
import {ConfiguredTextInput} from './ConfiguredTextInput'
import {ConfiguredSelectInput} from './ConfiguredSelectInput'

const I18n = useI18nScope('content_copy_redesign')

type Term = {id: string; label: string}

export const CopyCourseForm = () => {
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false)
  const [isBpCourse, setIsBpCourse] = useState<boolean>(false)
  const [courseName, setCourseName] = useState<string>('')
  const [courseCode, setCourseCode] = useState<string>('')
  const [newCourseStartDate, setNewCourseStartDate] = useState<Date | null>(null)
  const [newCourseEndDate, setNewCourseEndDate] = useState<Date | null>(null)
  const [terms, setTerms] = useState<Term[]>([])
  const [selectedTerm, setSelectedTerm] = useState<Term | null>(null)

  const handleSubmit = () => {
    setIsSubmitting(true)
  }

  const handleCancel = () => {
    window.history.back()
  }

  const handleTextInputChange = (value: string, setter: Dispatch<string>) => {
    setter(value)
  }

  const handleSetDate = (date: Date | null, setter: Dispatch<Date | null>) => {
    setter(date)
  }

  const handleSelectTerm = (selectedId: string | null) => {
    if (!selectedId) return
    const term = terms.find(({id}) => id === selectedId)
    term && setSelectedTerm(term)
  }

  const parsedEnvOldStartDate = parseDateToISOString(ENV.OLD_START_DATE)
  const parsedEnvOldEndDate = parseDateToISOString(ENV.OLD_END_DATE)
  const isoNewCourseStartDate = newCourseStartDate?.toISOString()
  const isoNewCourseEndDate = newCourseEndDate?.toISOString()

  return (
    <View as="div" margin="small none xx-large none">
      <Heading level="h1" margin="0 0 small">
        {I18n.t('Copy course')}
      </Heading>
      <Text size="large">{I18n.t('Please enter the details for the new course.')}</Text>
      <View as="div" margin="large none none none" width="100%" maxWidth="28.75rem">
        <View as="div" margin="medium none none none">
          <ConfiguredTextInput
            label={I18n.t('Name')}
            inputValue={courseName}
            onChange={value => handleTextInputChange(value, setCourseName)}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredTextInput
            label={I18n.t('Course code')}
            inputValue={courseCode}
            onChange={value => handleTextInputChange(value, setCourseCode)}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredDateInput
            selectedDate={isoNewCourseStartDate}
            onSelectedDateChange={d => handleSetDate(d, setNewCourseStartDate)}
            placeholder={I18n.t('Select a date (optional)')}
            renderLabelText={I18n.t('Start date')}
            renderScreenReaderLabelText={I18n.t('Select a new beginning date')}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredDateInput
            selectedDate={isoNewCourseEndDate}
            onSelectedDateChange={d => handleSetDate(d, setNewCourseEndDate)}
            placeholder={I18n.t('Select a date (optional)')}
            renderLabelText={I18n.t('End date')}
            renderScreenReaderLabelText={I18n.t('Select a new end date')}
          />
        </View>
        <View as="div" margin="medium none none none">
          <ConfiguredSelectInput
            label={I18n.t('Term')}
            defaultInputValue={terms[0]?.label}
            options={terms}
            onSelect={selectedId => handleSelectTerm(selectedId)}
          />
        </View>
      </View>
      <CommonMigratorControls
        canAdjustDates={true}
        canSelectContent={true}
        canImportBPSettings={isBpCourse}
        canImportAsNewQuizzes={ENV.NEW_QUIZZES_MIGRATION}
        newStartDate={parsedEnvOldStartDate}
        newEndDate={parsedEnvOldEndDate}
        oldStartDate={parsedEnvOldStartDate}
        oldEndDate={parsedEnvOldEndDate}
        fileUploadProgress={null}
        isSubmitting={isSubmitting}
        onCancel={handleCancel}
        onSubmit={handleSubmit}
        SubmitLabel={CreateCourseLabel}
      />
    </View>
  )
}
