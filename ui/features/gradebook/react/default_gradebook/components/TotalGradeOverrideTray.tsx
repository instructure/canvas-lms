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
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Avatar} from '@instructure/ui-avatar'
import {CloseButton} from '@instructure/ui-buttons'
import Carousel from './Carousel'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import GradeOverrideTrayRadioInputGroup from './GradeOverrideTrayRadioInputGroup'
import {GradeStatus} from '@canvas/grading/accountGradingStatus'

import useStore from '../stores'
import {gradeOverrideCustomStatus} from '../FinalGradeOverrides/FinalGradeOverride.utils'
import {useFinalGradeOverrideCustomStatus} from '../hooks/useFinalGradeOverrideCustomStatus'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {ApiCallStatus} from '@canvas/util/apiRequest'

const I18n = useI18nScope('gradebook')

export type TotalGradeOverrideTrayProps = {
  customGradeStatuses: GradeStatus[]
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
  customGradeStatuses,
  selectedGradingPeriodId,
  navigateDown,
  navigateUp,
}: TotalGradeOverrideTrayProps) {
  const {finalGradeOverrideTrayProps, toggleFinalGradeOverrideTray, finalGradeOverrides} =
    useStore()
  const {isOpen, isFirstStudent, isLastStudent, studentInfo, gradeEntry, gradeInfo} =
    finalGradeOverrideTrayProps

  const {saveFinalOverrideCustomStatus, saveCallStatus} = useFinalGradeOverrideCustomStatus()

  useEffect(() => {
    if (saveCallStatus === ApiCallStatus.FAILED) {
      showFlashError(I18n.t('There was an error saving the custom grade status.'))(new Error())
    }
  }, [saveCallStatus])

  if (!studentInfo) {
    return null
  }

  const selectedCustomStatusId = gradeOverrideCustomStatus(
    finalGradeOverrides,
    studentInfo.id,
    selectedGradingPeriodId
  )

  const {name, avatarUrl, gradesUrl, enrollmentId} = studentInfo

  const dismissTray = () => {
    toggleFinalGradeOverrideTray(false)
  }

  const handleRadioInputChanged = async (newCustomStatusId: string | null) => {
    const gradingPeriodId = selectedGradingPeriodId === '0' ? null : selectedGradingPeriodId
    await saveFinalOverrideCustomStatus(newCustomStatusId, enrollmentId, gradingPeriodId)

    const finalGradeOverrideToUpdate = {...finalGradeOverrides[studentInfo.id]}
    if (!gradingPeriodId && finalGradeOverrideToUpdate.courseGrade) {
      finalGradeOverrideToUpdate.courseGrade.customGradeStatusId = newCustomStatusId
    } else if (
      gradingPeriodId &&
      finalGradeOverrideToUpdate.gradingPeriodGrades?.[gradingPeriodId]
    ) {
      finalGradeOverrideToUpdate.gradingPeriodGrades[gradingPeriodId].customGradeStatusId =
        newCustomStatusId
    }

    useStore.setState({
      finalGradeOverrides: {
        ...finalGradeOverrides,
        finalGradeOverrideToUpdate,
      },
    })
  }

  const gradeInfoInput =
    gradeEntry && gradeInfo ? gradeEntry.formatGradeInfoForInput(gradeInfo) : ''

  const radioInputDisabled = gradeInfoInput === '' || saveCallStatus === ApiCallStatus.PENDING

  return (
    <Tray
      label={I18n.t('Final Grade Override Tray')}
      open={isOpen}
      onDismiss={dismissTray}
      shouldContainFocus={true}
      shouldCloseOnDocumentClick={true}
      size="small"
      placement="end"
    >
      <View as="div" padding="0" data-testid="total-grade-override-tray">
        <CloseButton
          placement="start"
          onClick={dismissTray}
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
            <ApplyTheme theme={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}>
              <Link href={gradesUrl} isWithinText={false}>
                {name}
              </Link>
            </ApplyTheme>
          </Carousel>

          <View as="div" margin="small 0" className="hr" />

          <View as="div" margin="medium 0">
            <Heading level="h4" as="h2" margin="auto auto small">
              <Text weight="bold">{I18n.t('Final Grade Override')}</Text>
            </Heading>
          </View>

          <View as="div" margin="medium 0">
            <TextInput
              renderLabel={<ScreenReaderContent>{I18n.t('Grade Override')}</ScreenReaderContent>}
              value={gradeInfoInput}
              disabled={true}
              width="4rem"
            />
          </View>

          <View as="div" margin="small 0" className="hr" />

          <View as="div" margin="medium 0">
            <GradeOverrideTrayRadioInputGroup
              disabled={radioInputDisabled}
              handleRadioInputChanged={handleRadioInputChanged}
              customGradeStatuses={customGradeStatuses}
              selectedCustomStatusId={selectedCustomStatusId}
            />
          </View>
        </View>
      </View>
    </Tray>
  )
}
