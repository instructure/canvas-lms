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

import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignments_2_student_content_rubric_self_assessment')

import {isSubmitted} from '../../helpers/SubmissionHelpers'
type SelfAssessmentButtonProps = {
  isEnabled: boolean
  onOpenSelfAssessmentTrigger: () => void
}

export const SelfAssessmentButton = ({
  isEnabled,
  onOpenSelfAssessmentTrigger,
}: SelfAssessmentButtonProps) => {
  return (
    <Button
      id="self-assess-button"
      data-testid="self-assess-button"
      disabled={!isEnabled}
      color="primary"
      withBackground={false}
      onClick={onOpenSelfAssessmentTrigger}
    >
      {I18n.t('Self-Assess')}
    </Button>
  )
}
