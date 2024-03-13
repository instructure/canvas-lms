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

import React, {useRef, useState, useCallback} from 'react'
import {throttle} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import doFetchApi from '@canvas/do-fetch-api-effect'
import CommonMigratorControls from './common_migrator_controls'
import type {onSubmitMigrationFormCallback} from '../types'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('content_migrations_redesign')

type CourseOption = {
  id: string
  label: string
}

type CourseCopyImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
}

export const CourseCopyImporter = ({onSubmit, onCancel}: CourseCopyImporterProps) => {
  const [searchParam, setSearchParam] = useState<string>('')
  const [courseOptions, setCourseOptions] = useState<any>([])
  const [selectedCourse, setSelectedCourse] = useState<any>(false)
  const [selectedCourseError, setSelectedCourseError] = useState<boolean>(false)
  const [includeCompletedCourses, setIncludeCompletedCourses] = useState<boolean>(false)

  const throttledCourseFetch = useRef(
    throttle(
      (currentSearchParam: string, includeConcluded: boolean) => {
        if (!currentSearchParam) {
          setCourseOptions([])
          return
        }
        doFetchApi({
          path: `/users/${
            window.ENV.current_user.id
          }/manageable_courses?term=${currentSearchParam}${
            includeConcluded ? '&include=concluded' : ''
          }`,
        })
          .then((response: any) => {
            setCourseOptions(response.json)
          })
          .catch(showFlashError(I18n.t("Couldn't load course options")))
      },
      500,
      {
        leading: false,
        trailing: true,
      }
    )
  )

  const getCourseOptions = useCallback(
    (e: React.SyntheticEvent<Element, Event>) => {
      const target = e.target as HTMLInputElement
      setSelectedCourse(false)
      setSearchParam(target.value)
      throttledCourseFetch.current(target.value, includeCompletedCourses)
    },
    [includeCompletedCourses]
  )

  const selectCourse = useCallback(
    (course_id: string) => {
      setSelectedCourse(
        courseOptions.filter((c: CourseOption) => {
          return c.id === course_id
        })[0]
      )
      setCourseOptions([])
      setSearchParam(selectedCourse.label)
    },
    [courseOptions, selectedCourse]
  )

  const handleSubmit: onSubmitMigrationFormCallback = useCallback(
    formData => {
      formData.settings.source_course_id = selectedCourse.id
      setSelectedCourseError(!selectedCourse)
      if (!selectedCourse) {
        return
      }
      onSubmit(formData)
    },
    [selectedCourse, onSubmit]
  )

  return (
    <>
      <View as="div" margin="medium none none none" width="100%" maxWidth="22.5rem">
        <Select
          inputValue={selectedCourse ? selectedCourse.label : searchParam}
          onInputChange={getCourseOptions}
          onRequestSelectOption={(_e: any, data: {id?: string | undefined}) => {
            const course_id = data.id as string
            selectCourse(course_id)
          }}
          placeholder={I18n.t('Search...')}
          isShowingOptions={courseOptions.length > 0}
          renderLabel={I18n.t('Search for a course')}
          renderBeforeInput={<IconSearchLine inline={false} />}
          onBlur={() => {
            setCourseOptions([])
          }}
          messages={
            selectedCourseError
              ? [
                  {
                    text: (
                      <Text color="danger">
                        {I18n.t('You must select a course to copy content from')}
                      </Text>
                    ),
                    type: 'error',
                  },
                ]
              : []
          }
        >
          {courseOptions.length > 0 ? (
            courseOptions.map((option: CourseOption) => {
              return (
                <Select.Option id={option.id} key={option.id} value={option.id}>
                  {option.label}
                </Select.Option>
              )
            })
          ) : (
            <Select.Option id="empty-option" key="empty-option" value="" />
          )}
        </Select>
      </View>
      <View as="div" margin="small none none none">
        <Checkbox
          name="include_completed_courses"
          label={I18n.t('Include completed courses')}
          onChange={(e: React.SyntheticEvent<Element, Event>) => {
            const target = e.target as HTMLInputElement
            setIncludeCompletedCourses(target.checked)
          }}
        />
      </View>
      <CommonMigratorControls
        canSelectContent={true}
        canImportAsNewQuizzes={ENV.NEW_QUIZZES_MIGRATION}
        canAdjustDates={true}
        canImportBPSettings={
          selectedCourse && ENV.SHOW_BP_SETTINGS_IMPORT_OPTION ? selectedCourse.blueprint : false
        }
        onSubmit={handleSubmit}
        onCancel={onCancel}
      />
    </>
  )
}

export default CourseCopyImporter
