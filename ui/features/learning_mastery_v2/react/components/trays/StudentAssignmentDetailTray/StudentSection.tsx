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
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Navigator} from './Navigator'
import TruncateWithTooltip from '@canvas/instui-bindings/react/TruncateWithTooltip'
import {Avatar} from '@instructure/ui-avatar'
import {Student} from '../../../types/rollup'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface StudentSectionProps {
  currentStudent: Student
  masteryReportUrl: string
  hasPrevious: boolean
  hasNext: boolean
  onPrevious: () => void
  onNext: () => void
  nextLabel?: string
  previousLabel?: string
}

export const StudentSection: React.FC<StudentSectionProps> = ({
  currentStudent,
  masteryReportUrl,
  hasPrevious,
  hasNext,
  onPrevious,
  onNext,
  nextLabel = I18n.t('Next student'),
  previousLabel = I18n.t('Previous student'),
}) => {
  return (
    <Flex direction="column" gap="small">
      <Avatar
        alt={currentStudent.name}
        as="div"
        size="medium"
        name={currentStudent.name}
        src={currentStudent.avatar_url}
        margin="auto"
      />
      <Navigator
        hasPrevious={hasPrevious}
        hasNext={hasNext}
        previousLabel={previousLabel}
        nextLabel={nextLabel}
        onPrevious={onPrevious}
        onNext={onNext}
        data-testid="student-navigator"
      >
        <TruncateWithTooltip>{currentStudent.name}</TruncateWithTooltip>
      </Navigator>

      <View as="div" textAlign="center">
        <Link href={masteryReportUrl} isWithinText={false} target="_blank">
          {I18n.t('View Mastery Report')}
        </Link>
      </View>
    </Flex>
  )
}
