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

import {AlertManagerContext} from '../../../shared/components/AlertManager'
import {Assignment} from '../graphqlData/Assignment'
import I18n from 'i18n!assignments_2'
import React, {useContext, useEffect} from 'react'
import {Submission} from '../graphqlData/Submission'
import {Text} from '@instructure/ui-elements'

export const getCurrentAttempt = submission => {
  return submission && submission.attempt !== 0 ? submission.attempt : 1
}

export default function Attempt({assignment, submission}) {
  const current_attempt = getCurrentAttempt(submission)
  const {setOnSuccess} = useContext(AlertManagerContext)

  useEffect(() => {
    setOnSuccess(I18n.t('Now viewing Attempt %{current_attempt}', {current_attempt}))
  }, [current_attempt, setOnSuccess])

  return (
    <Text size="medium" weight="bold" data-test-id="attempt">
      {!assignment.allowedAttempts
        ? I18n.t('Attempt %{current_attempt}', {current_attempt})
        : I18n.t('Attempt %{current_attempt} of %{max_attempts}', {
            current_attempt,
            max_attempts: assignment.allowedAttempts.toString()
          })}
    </Text>
  )
}

Attempt.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}

