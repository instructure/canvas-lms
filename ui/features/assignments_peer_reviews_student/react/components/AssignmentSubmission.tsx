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

import React, {useState} from 'react'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import ErrorShip from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Submission} from '../AssignmentsPeerReviewsStudentTypes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('peer_reviews_student')

interface AssignmentSubmissionProps {
  submission: Submission
}

const AssignmentSubmission: React.FC<AssignmentSubmissionProps> = ({submission}) => {
  const [viewMode, setViewMode] = useState<'paper' | 'plain_text'>('paper')

  const renderTextEntry = () => {
    const submissionClass = `user_content ${viewMode}`

    return (
      <View as="div" background="secondary" padding="small">
        <Flex as="div" textAlign="end" margin="0 0 small 0">
          <SimpleSelect
            renderLabel=""
            value={viewMode}
            onChange={(_e, {value}) => setViewMode(value as 'paper' | 'plain_text')}
            data-testid="view-mode-selector"
          >
            <SimpleSelect.Option id="paper" value="paper">
              {I18n.t('Paper View')}
            </SimpleSelect.Option>
            <SimpleSelect.Option id="plain_text" value="plain_text">
              {I18n.t('Plain Text View')}
            </SimpleSelect.Option>
          </SimpleSelect>
        </Flex>
        <div
          id="submission_preview"
          className={submissionClass}
          data-testid="text-entry-content"
          role="document"
          style={{maxHeight: '45vh', overflow: 'auto'}}
          dangerouslySetInnerHTML={{
            __html: apiUserContent.convert(submission.body || ''),
          }}
        />
      </View>
    )
  }

  switch (submission.submissionType) {
    case 'online_text_entry':
      return renderTextEntry()
    default:
      return (
        <GenericErrorPage
          imageUrl={ErrorShip}
          errorSubject={I18n.t('Submission type error')}
          errorCategory={I18n.t('Student Peer Review Submission Error Page.')}
          errorMessage={I18n.t('Submission type not yet supported.')}
        />
      )
  }
}

export default AssignmentSubmission
