/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useContext, useEffect} from 'react'
import PropTypes from 'prop-types'
import uniqBy from 'lodash/uniqBy'
import orderBy from 'lodash/orderBy'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('assignments_2')

export const getCurrentAttempt = submission => {
  return submission && submission.attempt !== 0 ? submission.attempt : 1
}

export default function AttemptSelect({submission, allSubmissions, onChangeSubmission}) {
  const current_attempt = getCurrentAttempt(submission)
  const {setOnSuccess} = useContext(AlertManagerContext)

  useEffect(() => {
    setOnSuccess(I18n.t('Now viewing Attempt %{current_attempt}', {current_attempt}))
  }, [current_attempt, setOnSuccess])

  // when there is more than one, filter out attempt 0 to avoid showing duplicates
  const filteredSubmissions =
    allSubmissions.length > 1 ? allSubmissions.filter(s => s.attempt !== 0) : allSubmissions

  const attemptList = orderBy(uniqBy(filteredSubmissions, 'attempt'), 'attempt').map(sub => {
    return [I18n.t('Attempt %{attempt}', {attempt: sub.attempt || 1}), sub.attempt]
  })

  function handleSubmissionChange(e, selectedOption) {
    const attempt = Number(selectedOption.value)
    onChangeSubmission(attempt)
  }

  return (
    <View as="div">
      <SimpleSelect
        renderLabel={<ScreenReaderContent>{I18n.t('Attempt')}</ScreenReaderContent>}
        width="15rem"
        value={`${submission.attempt}`}
        onChange={handleSubmissionChange}
        data-testid="attemptSelect"
      >
        {attemptList.map(([label, attempt]) => (
          <SimpleSelect.Option key={`${attempt}`} id={`opt-${attempt}`} value={`${attempt}`}>
            {label}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </View>
  )
}

AttemptSelect.propTypes = {
  allSubmissions: PropTypes.arrayOf(Submission.shape).isRequired,
  onChangeSubmission: PropTypes.func.isRequired,
  submission: Submission.shape.isRequired,
}
