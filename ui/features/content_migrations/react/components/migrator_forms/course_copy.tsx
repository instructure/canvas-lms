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
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError, showFlashSuccess} from '@instructure/platform-alerts'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {canvas} from '@instructure/ui-themes'
import {Responsive} from '@instructure/ui-responsive'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {CommonMigratorControls, type submitMigrationFormData} from '@canvas/content-migrations'
import {CanvasSelect} from '@instructure/platform-instui-bindings'
import type {onSubmitMigrationFormCallback} from '../types'
import {parseDateToISOString} from '../utils'
import {ImportLabel} from './import_label'
import {ImportInProgressLabel} from './import_in_progress_label'
import {ImportClearLabel} from './import_clear_label'
import AsyncCourseSearchSelect from './common_components/async_course_search_select'
import {CourseOption} from './types'
import {FormMessage} from '@instructure/ui-form-field'
import {MissingPolicyWarningModal} from '../MissingPolicyWarningModal'

const I18n = createI18nScope('content_migrations_redesign')

type CourseCopyImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  isSubmitting: boolean
}

export const CourseCopyImporter = ({onSubmit, onCancel, isSubmitting}: CourseCopyImporterProps) => {
  const isShowSelect = ENV.SHOW_SELECT
  const currentUser = ENV.current_user.id
  const nqMigration = ENV.NEW_QUIZZES_MIGRATION
  const showBpSettingImport = ENV.SHOW_BP_SETTINGS_IMPORT_OPTION
  const newStartDate = ENV.OLD_START_DATE
  const newEndDate = ENV.OLD_END_DATE

  const [preloadedCourses, setPreloadedCourses] = useState<Map<string, CourseOption[]>>(new Map())
  const [isPreloadedCoursesLoading, setIsPreloadedCoursesLoading] = useState<boolean>(false)
  const [selectedCourse, setSelectedCourse] = useState<CourseOption | null>(null)
  const [selectedCourseError, setSelectedCourseError] = useState<boolean>(false)
  const [includeCompletedCourses, setIncludeCompletedCourses] = useState<boolean>(true)
  const courseSelectInputRef = useRef<HTMLInputElement | null>(null)
  const courseSelectDropdownRef = useRef<HTMLInputElement | null>(null)
  const [showMissingPolicyWarning, setShowMissingPolicyWarning] = useState<boolean>(false)
  const pendingFormDataRef = useRef<submitMigrationFormData | null>(null)
  const [isDisablingPolicy, setIsDisablingPolicy] = useState<boolean>(false)
  const [isFetchingSourcePolicy, setIsFetchingSourcePolicy] = useState<boolean>(false)
  const sourceCourseHasMissingPolicyRef = useRef<boolean>(false)
  const latestCourseIdRef = useRef<string | null>(null)
  const [warningScenario, setWarningScenario] = useState<'destination' | 'source' | 'both' | null>(
    null,
  )

  const composeManageableCourseURL = useCallback(
    (currentSearchParam?: string, includeConcluded?: boolean) => {
      const params = new URLSearchParams()

      if (ENV.COURSE_ID) {
        params.set('current_course_id', ENV.COURSE_ID)
      }

      if (currentSearchParam) {
        params.set('term', currentSearchParam)
      }

      if (includeConcluded) {
        params.set('include', 'concluded')
      }

      return `/users/${currentUser}/manageable_courses?${params.toString()}`
    },
    [currentUser],
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

  const fetchSourceCourseLatePolicy = useCallback(async (courseId: string) => {
    latestCourseIdRef.current = courseId
    setIsFetchingSourcePolicy(true)
    try {
      const {json} = await doFetchApi<{
        late_policy?: {missing_submission_deduction_enabled?: boolean}
      }>({
        path: `/api/v1/courses/${courseId}/late_policy`,
      })
      if (latestCourseIdRef.current !== courseId) return
      sourceCourseHasMissingPolicyRef.current =
        json?.late_policy?.missing_submission_deduction_enabled || false
    } catch {
      if (latestCourseIdRef.current === courseId) {
        sourceCourseHasMissingPolicyRef.current = false
      }
    } finally {
      if (latestCourseIdRef.current === courseId) {
        setIsFetchingSourcePolicy(false)
      }
    }
  }, [])

  const addToPreloadedListIfNotExist = useCallback(
    (courseOption: CourseOption) => {
      const newMap = new Map(preloadedCourses)
      const courseOptionsToExtend = newMap.get(courseOption.term)
      if (!courseOptionsToExtend?.find((c: CourseOption) => c.id === courseOption.id)) {
        courseOptionsToExtend?.push(courseOption)
      }
      setPreloadedCourses(newMap)
    },
    [preloadedCourses],
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
        fetchSourceCourseLatePolicy(courseOption.id)
      } else {
        setSelectedCourse(null)
        sourceCourseHasMissingPolicyRef.current = false
      }
    },
    [preloadedCourses, fetchSourceCourseLatePolicy],
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

      const destinationHasMissingPolicy = ENV.MISSING_POLICY_ENABLED
      const sourceHasMissingPolicy = sourceCourseHasMissingPolicyRef.current
      const isAdjustingDates = formData.adjust_dates?.enabled
      const hasPolicyIssue =
        (destinationHasMissingPolicy || sourceHasMissingPolicy) && !isAdjustingDates

      if (hasPolicyIssue) {
        if (destinationHasMissingPolicy && sourceHasMissingPolicy) {
          setWarningScenario('both')
        } else if (destinationHasMissingPolicy) {
          setWarningScenario('destination')
        } else {
          setWarningScenario('source')
        }
        pendingFormDataRef.current = formData
        setShowMissingPolicyWarning(true)
        return
      }

      onSubmit(formData)
    },
    [selectedCourse, onSubmit, isShowSelect],
  )

  const handleDisablePolicy = useCallback(async () => {
    setIsDisablingPolicy(true)
    try {
      const destinationHasPolicy = ENV.MISSING_POLICY_ENABLED
      const shouldDisableDestination =
        warningScenario === 'destination' || warningScenario === 'both'

      if (shouldDisableDestination && destinationHasPolicy) {
        await doFetchApi({
          path: `/api/v1/courses/${ENV.COURSE_ID}/late_policy`,
          method: 'PATCH',
          body: {
            late_policy: {
              missing_submission_deduction_enabled: false,
            },
          },
        })
      }

      if (pendingFormDataRef.current) {
        const currentSkips = (pendingFormDataRef.current.settings.importer_skips as string[]) || []
        if (!currentSkips.includes('LatePolicy')) {
          pendingFormDataRef.current = {
            ...pendingFormDataRef.current,
            settings: {
              ...pendingFormDataRef.current.settings,
              importer_skips: [...currentSkips, 'LatePolicy'],
            },
          }
        }
      }

      if (warningScenario === 'destination') {
        showFlashSuccess(I18n.t('Missing submission policy has been disabled.'))
      } else if (warningScenario === 'source') {
        showFlashSuccess(I18n.t('Late policy will not be imported from the source course.'))
      } else if (warningScenario === 'both') {
        showFlashSuccess(
          I18n.t(
            'Missing submission policy has been disabled and late policy will not be imported.',
          ),
        )
      }

      setShowMissingPolicyWarning(false)
      if (pendingFormDataRef.current) {
        onSubmit(pendingFormDataRef.current)
        pendingFormDataRef.current = null
      }
    } catch {
      showFlashError(I18n.t('Failed to update missing submission policy settings.'))
    } finally {
      setIsDisablingPolicy(false)
    }
  }, [onSubmit, warningScenario])

  const handleImportAnyway = useCallback(() => {
    setShowMissingPolicyWarning(false)
    if (pendingFormDataRef.current) {
      onSubmit(pendingFormDataRef.current)
      pendingFormDataRef.current = null
    }
  }, [onSubmit])

  const handleCancelWarning = useCallback(() => {
    setShowMissingPolicyWarning(false)
    pendingFormDataRef.current = null
    setWarningScenario(null)
  }, [])

  const interaction =
    isSubmitting || isPreloadedCoursesLoading || isFetchingSourcePolicy ? 'disabled' : 'enabled'
  const messages = selectedCourseError
    ? [
        {
          text: I18n.t('You must select a course to copy content from'),
          type: 'newError',
        },
      ]
    : []
  const value = selectedCourse ? selectedCourse.id : ''

  // Prefer locale date, fallback if unavailable
  const oldStartDate = selectedCourse?.start_at_locale || selectedCourse?.start_at
  const oldEndDate = selectedCourse?.end_at_locale || selectedCourse?.end_at

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
              <Flex
                gap="small"
                direction={matches?.includes('changeToColumnDirection') ? 'row' : 'column'}
              >
                {isShowSelect && (
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
                        <CanvasSelect.Option key="emptyOption" id="emptyOption" value="">
                          {I18n.t('Select a course')}
                        </CanvasSelect.Option>
                        {Array.from(preloadedCourses.entries()).map(
                          ([term, courseOptions], index) => (
                            <CanvasSelect.Group label={term} key={`grp-${index}`}>
                              {courseOptions.map(courseOption => (
                                <CanvasSelect.Option
                                  key={courseOption.id}
                                  id={courseOption.id}
                                  value={courseOption.id}
                                >
                                  {courseOption.label}
                                </CanvasSelect.Option>
                              ))}
                            </CanvasSelect.Group>
                          ),
                        )}
                      </CanvasSelect>
                    </Flex.Item>
                    <Flex.Item>
                      <View
                        as="div"
                        padding={
                          matches?.includes('changeToColumnDirection') ? dividerTextPadding : '0'
                        }
                      >
                        <Text>{I18n.t('or')}</Text>
                      </View>
                    </Flex.Item>
                  </>
                )}
                <Flex.Item shouldGrow={true} overflowY="visible">
                  <AsyncCourseSearchSelect
                    selectedCourse={selectedCourse}
                    interaction={interaction}
                    getCourseOptions={async (term: string) => {
                      return doFetchApi({
                        path: composeManageableCourseURL(term, includeCompletedCourses),
                      })
                        .then(res => res.json as CourseOption[])
                        .catch(() => {
                          showFlashError(I18n.t("Couldn't load course options"))
                          return []
                        })
                    }}
                    onSelectCourse={(course: CourseOption | null) => {
                      if (course) {
                        addToPreloadedListIfNotExist(course)
                        setSelectedCourse(course)
                        fetchSourceCourseLatePolicy(course.id)
                      } else {
                        setSelectedCourse(null)
                        sourceCourseHasMissingPolicyRef.current = false
                      }
                    }}
                    messages={messages as FormMessage[]}
                    inputRef={ref => (courseSelectInputRef.current = ref)}
                  />
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
        canCopyIntegrationInfo={!!ENV.COPY_COURSE_INTEGRATION_INFO}
        oldStartDate={parseDateToISOString(oldStartDate)}
        oldEndDate={parseDateToISOString(oldEndDate)}
        newStartDate={parseDateToISOString(newStartDate)}
        newEndDate={parseDateToISOString(newEndDate)}
        onSubmit={handleSubmit}
        onCancel={onCancel}
        SubmitLabel={ImportLabel}
        SubmittingLabel={ImportInProgressLabel}
        CancelLabel={ImportClearLabel}
      />
      <MissingPolicyWarningModal
        open={showMissingPolicyWarning}
        onCancel={handleCancelWarning}
        onDisablePolicy={handleDisablePolicy}
        onImportAnyway={handleImportAnyway}
        isDisabling={isDisablingPolicy}
        scenario={warningScenario}
      />
    </>
  )
}

export default CourseCopyImporter
