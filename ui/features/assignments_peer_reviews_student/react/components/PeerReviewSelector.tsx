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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AssessmentRequest} from '../hooks/useAssignmentQuery'

const I18n = createI18nScope('peer_reviews_student')

interface PeerReviewSelectorProps {
  assessmentRequests: AssessmentRequest[]
  selectedIndex: number
  onSelectionChange: (index: number) => void
}

export const PeerReviewSelector = ({
  assessmentRequests,
  selectedIndex,
  onSelectionChange,
}: PeerReviewSelectorProps) => {
  const hasAssessments = assessmentRequests && assessmentRequests.length > 0

  const handleChange = (_event: React.SyntheticEvent, data: {value?: string | number}) => {
    const index = Number(data.value)
    onSelectionChange(index)
  }

  return (
    <SimpleSelect
      renderLabel={<ScreenReaderContent>{I18n.t('Select peer to review')}</ScreenReaderContent>}
      value={hasAssessments ? String(selectedIndex >= 0 ? selectedIndex : 0) : 'no-peer-reviews'}
      onChange={handleChange}
      data-testid="peer-review-selector"
      width="15rem"
      assistiveText={I18n.t('Use arrow keys to navigate options. Press Enter to select.')}
    >
      {hasAssessments ? (
        assessmentRequests.map((assessment, index) => (
          <SimpleSelect.Option
            key={assessment._id}
            id={`peer-review-option-${index}`}
            value={String(index)}
          >
            {I18n.t('Peer Review (%{number} of %{total})', {
              number: index + 1,
              total: assessmentRequests.length,
            })}
          </SimpleSelect.Option>
        ))
      ) : (
        <SimpleSelect.Option id="no-peer-reviews" value="no-peer-reviews">
          {I18n.t('No peer reviews available')}
        </SimpleSelect.Option>
      )}
    </SimpleSelect>
  )
}
