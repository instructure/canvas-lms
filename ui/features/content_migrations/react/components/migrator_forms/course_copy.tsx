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

import React, {useRef, useState} from 'react'
import {throttle} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
// @ts-ignore
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
// @ts-ignore
import {IconSearchLine} from '@instructure/ui-icons'
import {Select} from '@instructure/ui-select'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {setSourceCourseType} from '../types'

const I18n = useI18nScope('content_migrations_redesign')

type CourseOption = {
  id: string
  label: string
}

export const CourseCopyImporter = ({setSourceCourse}: {setSourceCourse: setSourceCourseType}) => {
  const [searchParam, setSearchParam] = useState<string>('')
  const [courseOptions, setCourseOptions] = useState<any>([])
  const [selectedCourse, setSelectedCourse] = useState<any>(false)
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

  const getCourseOptions = (e: React.SyntheticEvent<Element, Event>) => {
    const target = e.target as HTMLInputElement
    setSelectedCourse(false)
    setSearchParam(target.value)
    throttledCourseFetch.current(target.value, includeCompletedCourses)
  }

  const selectCourse = (course_id: string) => {
    setSourceCourse(course_id)
    setSelectedCourse(
      courseOptions.filter((c: CourseOption) => {
        return c.id === course_id
      })[0]
    )
    setCourseOptions([])
    setSearchParam(selectedCourse.label)
  }

  return (
    <>
      <View as="div" margin="large none none none" width="100%" maxWidth="22.5rem">
        <Select
          inputValue={selectedCourse ? selectedCourse.label : searchParam}
          onInputChange={getCourseOptions}
          onRequestSelectOption={(_e: any, data: {id?: string | undefined}) => {
            const course_id = data.id as string
            selectCourse(course_id)
          }}
          isShowingOptions={courseOptions.length > 0}
          renderLabel={I18n.t('Search for a course')}
          renderBeforeInput={<IconSearchLine inline={false} />}
          onBlur={() => {
            setCourseOptions([])
          }}
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
            <Select.Option id="empty-option" key="empty-option" value="">
              ---
            </Select.Option>
          )}
        </Select>
      </View>
      <View as="div" margin="small none none none">
        <Checkbox
          name="include_completed_courses"
          value={1}
          label={I18n.t('Include completed courses')}
          onChange={(e: React.SyntheticEvent<Element, Event>) => {
            const target = e.target as HTMLInputElement
            setIncludeCompletedCourses(target.checked)
          }}
        />
      </View>
    </>
  )
}

export default CourseCopyImporter
