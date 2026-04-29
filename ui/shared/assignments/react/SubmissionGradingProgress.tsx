/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {ProgressCircle} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {IconCheckMarkSolid} from '@instructure/ui-icons'

const I18n = createI18nScope('submission_grading_progress')

interface SubmissionGradingProgressProps {
  totalSubmissions: number
  totalGradedSubmissions: number
}

enum GradingProgressStatus {
  NO_SUBMISSIONS = 'NO_SUBMISSIONS',
  NOT_STARTED = 'NOT_STARTED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETE = 'COMPLETE',
}

interface GradingProgressData {
  heading: string
  description: string
  gradingStatus: GradingProgressStatus
}

const getProgressData = (
  totalSubmissions: number,
  totalGradedSubmissions: number,
): GradingProgressData => {
  let heading = I18n.t('No Submissions')
  let description = I18n.t('No submitted assignments to grade')
  let gradingStatus = GradingProgressStatus.NO_SUBMISSIONS

  if (totalSubmissions > 0) {
    description = I18n.t(
      '%{totalGradedSubmissions} out of %{totalSubmissions} submissions graded',
      {
        totalGradedSubmissions,
        totalSubmissions,
      },
    )

    if (totalGradedSubmissions === 0) {
      heading = I18n.t('Grading Not Started')
      gradingStatus = GradingProgressStatus.NOT_STARTED
    } else if (totalGradedSubmissions < totalSubmissions) {
      heading = I18n.t('Grading In Progress')
      gradingStatus = GradingProgressStatus.IN_PROGRESS
    } else if (totalGradedSubmissions === totalSubmissions) {
      heading = I18n.t('Grading Complete')
      gradingStatus = GradingProgressStatus.COMPLETE
    }
  }

  return {heading, description, gradingStatus}
}

const SubmissionGradingProgress: React.FC<SubmissionGradingProgressProps> = ({
  totalSubmissions,
  totalGradedSubmissions,
}) => {
  const {heading, description, gradingStatus} = getProgressData(
    totalSubmissions,
    totalGradedSubmissions,
  )
  const screenReaderLabel = I18n.t(
    '%{totalGradedSubmissions} out of %{totalSubmissions} submissions have been graded for this assignment.',
    {
      totalGradedSubmissions,
      totalSubmissions,
    },
  )

  return (
    <Flex>
      <ProgressCircle
        size="x-small"
        meterColor="success"
        shouldAnimateOnMount
        screenReaderLabel={screenReaderLabel}
        formatScreenReaderValue={() => ''} // This keeps screen reader from reading the internal value of progress circle. We are already using the label for that purpose.
        valueNow={totalGradedSubmissions}
        valueMax={totalSubmissions || 1} // default value of 1 so the progress circle is empty if "0 out of 0"
        renderValue={() =>
          gradingStatus === GradingProgressStatus.COMPLETE ? (
            <IconCheckMarkSolid color="success" data-testid="complete-check-mark" />
          ) : null
        }
        data-testid="submission-grading-progress-circle"
      />
      <Flex direction="column" margin="0 x-small 0 0">
        <Text
          color={
            gradingStatus === GradingProgressStatus.IN_PROGRESS ||
            gradingStatus === GradingProgressStatus.COMPLETE
              ? 'success'
              : undefined
          }
          weight="weightImportant"
        >
          {heading}
        </Text>
        <Text>{description}</Text>
      </Flex>
    </Flex>
  )
}

export default SubmissionGradingProgress
