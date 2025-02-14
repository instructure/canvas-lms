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

import React, {useRef, useState, useCallback, type ChangeEvent, useEffect} from 'react'
import {throttle} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconSearchLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {canvas} from '@instructure/ui-theme-tokens'
import {Responsive} from '@instructure/ui-responsive'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {CommonMigratorControls} from '@canvas/content-migrations'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import type {onSubmitMigrationFormCallback} from '../types'
import {parseDateToISOString} from '../utils'
import {ImportLabel} from './import_label'
import {ImportInProgressLabel} from './import_in_progress_label'
import {ImportClearLabel} from './import_clear_label'

const I18n = createI18nScope('content_migrations_redesign')

type CourseOption = {
  id: string
  label: string
  term: string
  start_at: string
  end_at: string
  blueprint: boolean
}

type CourseCopyImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  isSubmitting: boolean
}

const getCourseOptionDescription = (option: CourseOption): string | null => {
  return option.term ? I18n.t('Term: %{termName}', {termName: option.term}) : null
}

export const CourseCopyImporter = ({onSubmit, onCancel, isSubmitting}: CourseCopyImporterProps) => {
  const isShowSelect = ENV.SHOW_SELECT
  const currentUser = ENV.current_user.id
  const nqMigration = ENV.NEW_QUIZZES_MIGRATION
  const showBpSettingImport = ENV.SHOW_BP_SETTINGS_IMPORT_OPTION
  const newStartDate = ENV.OLD_START_DATE
  const newEndDate = ENV.OLD_END_DATE

  const [searchParam, setSearchParam] = useState<string>('')
  const [courseOptions, setCourseOptions] = useState<Array<CourseOption>>([])
  const [preloadedCourses, setPreloadedCourses] = useState<Map<string, CourseOption[]>>(new Map())
  const [isPreloadedCoursesLoading, setIsPreloadedCoursesLoading] = useState<boolean>(false)
  const [selectedCourse, setSelectedCourse] = useState<CourseOption | null>(null)
  const [selectedCourseError, setSelectedCourseError] = useState<boolean>(false)
  const [includeCompletedCourses, setIncludeCompletedCourses] = useState<boolean>(true)
  const courseSelectInputRef = useRef<HTMLInputElement | null>(null)
  const courseSelectDropdownRef = useRef<HTMLInputElement | null>(null)

  const composeManageableCourseURL = useCallback(
    (currentSearchParam?: string, includeConcluded?: boolean) => {
      let url = `/users/${currentUser}/manageable_courses`

      if (currentSearchParam || includeConcluded) {
        url += '?'
      }
      if (currentSearchParam) {
        url += `term=${currentSearchParam}`
      }
      if (includeConcluded) {
        url += `${currentSearchParam ? '&' : ''}include=concluded`
      }
      return url
    },
    [currentUser]
  )

  useEffect(() => {
    const preLoadManageableCourses = async () => {
      try {
        setIsPreloadedCoursesLoading(true)
        const {json} = await doFetchApi<CourseOption[]>({
          path: composeManageableCourseURL(undefined, true),
        })
        if (json) {
          const coursesByTerms = json.reduce((groups, option) => {
            const term = option.term
            if (!groups.has(term)) {
              groups.set(term, [])
            }
            groups.get(term)?.push(option)
            return groups
          }, new Map<string, CourseOption[]>())
          setPreloadedCourses(coursesByTerms)
        }
      } catch {
        showFlashError(I18n.t("Couldn't pre load course options"))
      } finally {
        setIsPreloadedCoursesLoading(false)
      }
    }

    if (isShowSelect) {
      preLoadManageableCourses()
    }
  }, [composeManageableCourseURL, isShowSelect])


  const throttledCourseFetch = useRef(
    throttle(
      (currentSearchParam: string, includeConcluded: boolean) => {
        if (!currentSearchParam) {
          setCourseOptions([])
          return
        }
        doFetchApi({
          path: composeManageableCourseURL(currentSearchParam, includeConcluded),
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
      },
    ),
  )

  const getCourseOptions = useCallback(
    (e: React.SyntheticEvent<Element, Event>) => {
      const target = e.target as HTMLInputElement
      setSelectedCourse(null)
      setSearchParam(target.value)
      throttledCourseFetch.current(target.value, includeCompletedCourses)
    },
    [includeCompletedCourses],
  )

  const addToPreloadedListIfNotExist = useCallback(
    (courseOption: CourseOption) => {
      const newMap = new Map(preloadedCourses)
      const courseOptionsToExtend = newMap.get(courseOption.term)
      if (!courseOptionsToExtend?.find((c: CourseOption) => c.id === courseOption.id)) {
        courseOptionsToExtend?.push(courseOption)
      }
      setPreloadedCourses(newMap)
    },
    [preloadedCourses]
  )

  const selectCourse = useCallback(
    (_e: ChangeEvent<HTMLSelectElement>, courseId: string) => {
      const courseOption = courseOptions.find((c: CourseOption) => c.id === courseId)

      if (courseOption) {
        addToPreloadedListIfNotExist(courseOption)
        setSelectedCourse(courseOption)
        setSearchParam(courseOption.label)
        setCourseOptions([])
      }
    },
    [addToPreloadedListIfNotExist, courseOptions],
  )

  const selectPreloadedCourse = useCallback(
    (_e: ChangeEvent<HTMLSelectElement>, courseId: string) => {
      let courseOption

      for (const [_, courseOptions] of preloadedCourses.entries()) {
        courseOption = courseOptions.find((c: CourseOption) => c.id === courseId)
        if (courseOption) break
      }

      if (courseOption) {
        setSelectedCourse(courseOption)
        setSearchParam(courseOption.label)
      } else {
        setSelectedCourse(null)
        setSearchParam('')
      }
      setCourseOptions([])
    },
    [preloadedCourses],
  )
  const handleSubmit: onSubmitMigrationFormCallback = useCallback(
    formData => {
      formData.settings.source_course_id = selectedCourse?.id
      setSelectedCourseError(!selectedCourse)
      if (!selectedCourse) {
        if (isShowSelect) {
          courseSelectDropdownRef.current?.focus()
        } else {
          courseSelectInputRef.current?.focus()
        }
        return
      }
      onSubmit(formData)
    },
    [selectedCourse, onSubmit, isShowSelect],
  )

  const interaction = isSubmitting || isPreloadedCoursesLoading ? 'disabled' : 'enabled'
  const messages = selectedCourseError
    ? [
      {
        text: I18n.t('You must select a course to copy content from'),
        type: 'newError',
      },
    ]
    : []
  const value = selectedCourse ? selectedCourse.id : ''

  return (
    <>
      <View as="div" margin="medium none none none" width="100%" maxWidth="46.5rem">
        <Responsive
          match="media"
          query={{
            changeToColumnDirection: {minWidth: canvas.breakpoints.desktop},
          }}
          render={(_, matches) => {
            const dividerTextPadding = selectedCourseError ? 'small 0 small 0' : 'large 0 small 0'

            return (
              <Flex gap="small" direction={matches?.includes('changeToColumnDirection') ? 'row' : 'column'}>
                {isShowSelect &&
                  <>
                    <Flex.Item shouldGrow={true}>
                      <CanvasSelect
                        id="course-copy-select-preloaded-courses"
                        data-testid="course-copy-select-preloaded-courses"
                        // @ts-expect-error
                        inputValue={selectedCourse?.label}
                        interaction={interaction}
                        onChange={selectPreloadedCourse}
                        placeholder={I18n.t('Select...')}
                        renderLabel={I18n.t('Select a course')}
                        isRequired={true}
                        messages={messages}
                        value={value}
                        scrollToHighlightedOption={true}
                        inputRef={ref => (courseSelectDropdownRef.current = ref)}
                      >
                        <CanvasSelect.Option
                          key="emptyOption"
                          id="emptyOption"
                          value=""
                        >
                          {I18n.t('Select a course')}
                        </CanvasSelect.Option>
                        {Array.from(preloadedCourses.entries()).map(([term, courseOptions], index) => (
                          <CanvasSelect.Group label={term} key={`grp-${index}`}>
                            {courseOptions.map((courseOption) => (
                              <CanvasSelect.Option
                                key={courseOption.id}
                                id={courseOption.id}
                                value={courseOption.id}
                              >
                                {courseOption.label}
                              </CanvasSelect.Option>
                            ))}
                          </CanvasSelect.Group>
                        ))}
                      </CanvasSelect>
                    </Flex.Item>
                    <Flex.Item>
                      <View as="div" padding={matches?.includes('changeToColumnDirection') ? dividerTextPadding : '0'}>
                        <Text>{I18n.t('or')}</Text>
                      </View>
                    </Flex.Item>
                  </>
                }
                <Flex.Item shouldGrow={true} overflowY="visible">
                  <CanvasSelect
                    id="course-copy-select-course"
                    data-testid="course-copy-select-course"
                    // @ts-expect-error
                    inputValue={selectedCourse ? selectedCourse.label : searchParam}
                    interaction={interaction}
                    onChange={selectCourse}
                    onInputChange={getCourseOptions}
                    placeholder={I18n.t('Search...')}
                    isShowingOptions={courseOptions.length > 0}
                    renderLabel={I18n.t('Search for a course')}
                    isRequired={true}
                    renderBeforeInput={<IconSearchLine inline={false} />}
                    renderAfterInput={<span />}
                    onBlur={() => {
                      setCourseOptions([])
                    }}
                    messages={messages}
                    value={value}
                    scrollToHighlightedOption={true}
                    inputRef={ref => (courseSelectInputRef.current = ref)}
                  >
                    {courseOptions.length > 0 ? (
                      courseOptions.map((option: CourseOption) => {
                        return (
                          <CanvasSelect.Option
                            id={option.id}
                            key={option.id}
                            value={option.id}
                            description={getCourseOptionDescription(option)}
                          >
                            {option.label}
                          </CanvasSelect.Option>
                        )
                      })
                    ) : (
                      <CanvasSelect.Option id="empty-option" key="empty-option" value="" />
                    )}
                  </CanvasSelect>
                </Flex.Item>
              </Flex>
            )
          }}
        />
      </View>
      <View as="div" margin="small none none none">
        <Checkbox
          disabled={isSubmitting}
          checked={includeCompletedCourses}
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
        isSubmitting={isSubmitting}
        canImportAsNewQuizzes={nqMigration}
        canAdjustDates={true}
        fileUploadProgress={null}
        canImportBPSettings={
          selectedCourse && showBpSettingImport ? selectedCourse.blueprint : false
        }
        oldStartDate={parseDateToISOString(selectedCourse?.start_at)}
        oldEndDate={parseDateToISOString(selectedCourse?.end_at)}
        newStartDate={parseDateToISOString(newStartDate)}
        newEndDate={parseDateToISOString(newEndDate)}
        onSubmit={handleSubmit}
        onCancel={onCancel}
        SubmitLabel={ImportLabel}
        SubmittingLabel={ImportInProgressLabel}
        CancelLabel={ImportClearLabel}
      />
    </>
  )
}

export default CourseCopyImporter
