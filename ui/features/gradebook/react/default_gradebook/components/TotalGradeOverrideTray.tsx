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

import React, {useEffect} from 'react'
import {ApolloProvider, createClient} from '@canvas/apollo'
import {FinalGradeOverrideTextBox} from '@canvas/final-grade-override'
import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Avatar} from '@instructure/ui-avatar'
import {CloseButton} from '@instructure/ui-buttons'
import Carousel from './Carousel'
import {InstUISettingsProvider} from '@instructure/emotion'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import GradeOverrideTrayRadioInputGroup from './GradeOverrideTrayRadioInputGroup'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'

import useStore from '../stores'
import {gradeOverrideCustomStatus} from '../FinalGradeOverrides/FinalGradeOverride.utils'
import {useFinalGradeOverrideCustomStatus} from '../hooks/useFinalGradeOverrideCustomStatus'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {ApiCallStatus} from '@canvas/do-fetch-api-effect/apiRequest'

const I18n = useI18nScope('gradebook')

const componentOverrides = {
  Link: {
    mediumPaddingHorizontal: 0,
    mediumHeight: 'normal',
  },
}

export type TotalGradeOverrideTrayProps = {
  customGradeStatuses: GradeStatusUnderscore[]
  handleDismiss: (manualDismiss: boolean) => void
  handleOnGradeChange: (studentId: string, grade: GradeOverrideInfo) => void
  selectedGradingPeriodId?: string
  navigateDown: () => void
  navigateUp: () => void
}

export function TotalGradeOverrideTrayProvider(props: TotalGradeOverrideTrayProps) {
  return (
    <ApolloProvider client={createClient()}>
      <TotalGradeOverrideTray {...props} />
    </ApolloProvider>
  )
}

export function TotalGradeOverrideTray({
  customGradeStatuses = [],
  selectedGradingPeriodId,
  handleDismiss,
  handleOnGradeChange,
  navigateDown,
  navigateUp,
}: TotalGradeOverrideTrayProps) {
  const {finalGradeOverrideTrayProps, toggleFinalGradeOverrideTray, finalGradeOverrides} =
    useStore()

  const {saveFinalOverrideCustomStatus, saveCallStatus} = useFinalGradeOverrideCustomStatus()

  useEffect(() => {
    if (saveCallStatus === ApiCallStatus.FAILED) {
      showFlashError(I18n.t('There was an error saving the custom grade status.'))(new Error())
    }
  }, [saveCallStatus])

  if (!finalGradeOverrideTrayProps) {
    return null
  }

  const {isOpen, isFirstStudent, isLastStudent, studentInfo, gradeEntry} =
    finalGradeOverrideTrayProps

  if (!studentInfo) {
    return null
  }

  const {id: studentId} = studentInfo

  const selectedCustomStatusId = gradeOverrideCustomStatus(
    finalGradeOverrides,
    studentId,
    selectedGradingPeriodId
  )

  const selectedCustomStatus = customGradeStatuses.find(
    status => status.id === selectedCustomStatusId
  )

  const {name, avatarUrl, gradesUrl, enrollmentId} = studentInfo

  const getNullableSelectedGradingPeriodId = (): string | null | undefined => {
    return selectedGradingPeriodId === '0' ? null : selectedGradingPeriodId
  }

  const dismissTray = (manualDismiss: boolean) => {
    toggleFinalGradeOverrideTray(false)
    handleDismiss(manualDismiss)
  }

  const handleRadioInputChanged = async (newCustomStatusId: string | null) => {
    const gradingPeriodId = getNullableSelectedGradingPeriodId()
    await saveFinalOverrideCustomStatus(newCustomStatusId, enrollmentId, gradingPeriodId)

    const {id: studentId} = studentInfo
    const finalGradeOverrideToUpdate = finalGradeOverrides[studentId] ?? {}

    if (gradingPeriodId) {
      if (!finalGradeOverrideToUpdate.gradingPeriodGrades?.[gradingPeriodId]) {
        finalGradeOverrideToUpdate.gradingPeriodGrades = {
          [gradingPeriodId]: {},
        }
      }

      finalGradeOverrideToUpdate.gradingPeriodGrades[gradingPeriodId].customGradeStatusId =
        newCustomStatusId
    } else {
      if (!finalGradeOverrideToUpdate.courseGrade) {
        finalGradeOverrideToUpdate.courseGrade = {}
      }

      finalGradeOverrideToUpdate.courseGrade.customGradeStatusId = newCustomStatusId
    }

    useStore.setState({
      finalGradeOverrides: {
        ...finalGradeOverrides,
        [studentId]: finalGradeOverrideToUpdate,
      },
    })
  }

  const studentFinalGradeOverrides = finalGradeOverrides[studentId]
  const gradingPeriodId = getNullableSelectedGradingPeriodId()

  const studentFinalGradePercentage = gradingPeriodId
    ? studentFinalGradeOverrides?.gradingPeriodGrades?.[gradingPeriodId]?.percentage
    : studentFinalGradeOverrides?.courseGrade?.percentage

  return (
    <Tray
      label={I18n.t('Final Grade Override Tray')}
      open={isOpen}
      onDismiss={() => dismissTray(false)}
      shouldContainFocus={true}
      shouldCloseOnDocumentClick={true}
      size="small"
      placement="end"
    >
      <View as="div" padding="0" data-testid="total-grade-override-tray">
        <CloseButton
          placement="start"
          onClick={() => dismissTray(true)}
          screenReaderLabel={I18n.t('Close total grade override tray')}
        />

        <View as="div" className="SubmissionTray__Container">
          <View as="div" id="SubmissionTray__Avatar">
            <Avatar name={name} src={avatarUrl} size="auto" data-fs-exclude={true} />
          </View>

          <Carousel
            id="student-carousel"
            disabled={false}
            displayLeftArrow={!isFirstStudent}
            displayRightArrow={!isLastStudent}
            leftArrowDescription={I18n.t('Previous student')}
            onLeftArrowClick={() => navigateUp()}
            onRightArrowClick={() => navigateDown()}
            rightArrowDescription={I18n.t('Next student')}
          >
            <InstUISettingsProvider theme={{componentOverrides}}>
              <Link href={gradesUrl} isWithinText={false}>
                {name}
              </Link>
            </InstUISettingsProvider>
          </Carousel>

          <View as="div" margin="small 0" className="hr" />

          <View as="div" margin="medium 0">
            <Heading level="h4" as="h2" margin="auto auto small">
              <Text weight="bold">{I18n.t('Final Grade Override')}</Text>
            </Heading>
          </View>

          <View as="div" margin="medium 0">
            <FinalGradeOverrideTextBox
              onGradeChange={newGrade => {
                handleOnGradeChange(studentId, newGrade)
              }}
              finalGradeOverride={studentFinalGradeOverrides}
              gradingPeriodId={gradingPeriodId}
              gradingScheme={gradeEntry?.gradingScheme}
              showPercentageLabel={false}
              width="4rem"
              disabled={selectedCustomStatus?.allow_final_grade_value === false}
            />
          </View>

          {customGradeStatuses.length > 0 && (
            <>
              <View as="div" margin="small 0" className="hr" />

              <View as="div" margin="medium 0">
                <GradeOverrideTrayRadioInputGroup
                  disabled={saveCallStatus === ApiCallStatus.PENDING}
                  hasOverrideScore={
                    studentFinalGradePercentage !== null &&
                    studentFinalGradePercentage !== undefined
                  }
                  handleRadioInputChanged={handleRadioInputChanged}
                  customGradeStatuses={customGradeStatuses}
                  selectedCustomStatusId={selectedCustomStatusId}
                />
              </View>
            </>
          )}
        </View>
      </View>
    </Tray>
  )
}
