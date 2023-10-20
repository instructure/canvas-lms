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

import React, {useState, useContext, useEffect} from 'react'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useMutation} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'

import {UPDATE_SUBMISSION_STUDENT_ENTERED_SCORE} from '../../graphql/Mutations'

import {IconDiscussionReply2Line} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {Submission} from '../../graphql/Submission'
import {View} from '@instructure/ui-view'

import {formatNumber} from './utils'

const I18n = useI18nScope('grade_summary')

const updateCache = (cache, {data}) => {
  const options = {
    id: data.updateSubmissionStudentEnteredScore.submission.id,
    fragment: Submission.fragment,
    fragmentName: 'Submission',
  }

  const updatedSubmission = JSON.parse(JSON.stringify(cache.readFragment(options)))
  if (updatedSubmission) {
    updatedSubmission.studentEnteredScore =
      data.updateSubmissionStudentEnteredScore.submission.studentEnteredScore
    cache.writeFragment({
      ...options,
      data: {...data.updateSubmissionStudentEnteredScore.submission, __typename: 'Submission'},
    })
  }
}

const WhatIfGrade = ({assignment, setActiveWhatIfScores, activeWhatIfScores}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const submission = assignment?.submissionsConnection?.nodes[0] || {}

  const [showInput, setShowInput] = useState(true)
  const [whatIfValue, setWhatIfValue] = useState(`${submission.score || 0}`)
  const [updatedSubmission] = useMutation(UPDATE_SUBMISSION_STUDENT_ENTERED_SCORE, {
    onCompleted(data) {
      if (data.updateSubmissionStudentEnteredScore.errors) {
        setOnFailure(I18n.t('What if score change operation failed'))
      } else {
        setOnSuccess(I18n.t('What if score updated'))
      }
    },
    onError: () => {
      setOnFailure(I18n.t('Read state change failed'))
    },
    update: updateCache,
    optimisticResponse: () => {
      return {
        updateSubmissionStudentEnteredScore: {
          submission: {
            ...submission,
            studentEnteredScore: Number.parseFloat(whatIfValue) || 0,
          },
          __typename: 'UpdateSubmissionStudentEnteredScorePayload',
        },
      }
    },
  })

  const handleHideWhatIfScore = () => {
    setActiveWhatIfScores(activeWhatIfScores.filter(id => assignment._id !== id))
    setShowInput(false)
  }

  const handleScoreChange = event => {
    event.preventDefault()

    if (!/^\d*\.?\d*$/.test(event.target.value)) {
      return
    }
    setWhatIfValue(event.target.value)
  }

  const handleScoreKeyDown = event => {
    if (event.key === 'Enter') {
      event.preventDefault()
      updateSubmissionWhatIfScore()
    } else if (event.key === 'Escape') {
      handleHideWhatIfScore()
    }
  }

  const updateSubmissionWhatIfScore = () => {
    setShowInput(false)
    updatedSubmission({
      variables: {
        submissionId: submission._id,
        enteredScore: Number.parseFloat(whatIfValue) || 0,
        courseID: ENV.course_id,
      },
    })
  }

  useEffect(() => {
    updatedSubmission({
      variables: {
        submissionId: submission._id,
        enteredScore: Number.parseFloat(submission.score) || 0,
        courseID: ENV.course_id,
      },
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (showInput) {
      document.querySelector(`[data-testid=what_if_score_input_${assignment._id}]`)?.focus()
    }
  }, [assignment._id, showInput])

  return (
    <Flex>
      {showInput ? (
        <Flex.Item>
          <Tooltip renderTip={I18n.t('Enter a score to test')}>
            <TextInput
              data-testid={`what_if_score_input_${assignment._id}`}
              onKeyDown={handleScoreKeyDown}
              onChange={handleScoreChange}
              renderLabel={
                <ScreenReaderContent>
                  {I18n.t('What if score input for %{assignmentName}', {
                    assignmentName: assignment.name,
                  })}
                </ScreenReaderContent>
              }
              value={whatIfValue}
              showArrows={false}
              onBlur={updateSubmissionWhatIfScore}
            />
          </Tooltip>
        </Flex.Item>
      ) : (
        <>
          <Flex.Item>
            <Tooltip renderTip={I18n.t('Reset to original score')}>
              <IconButton
                data-testid="reset_what_if_score"
                screenReaderLabel={I18n.t('Reset what if score')}
                size="small"
                margin="0 small 0 0"
                onClick={handleHideWhatIfScore}
              >
                <IconDiscussionReply2Line />
              </IconButton>
            </Tooltip>
          </Flex.Item>
          <Flex.Item onClick={() => setShowInput(true)}>
            <View
              tabIndex="0"
              role="button"
              position="relative"
              onKeyDown={event => {
                if (event.key === 'Enter') {
                  setShowInput(true)
                }
              }}
            >
              <Tooltip renderTip={I18n.t('This is a what if score')}>
                <View as="span">
                  {submission?.studentEnteredScore % 1 === 0
                    ? submission?.studentEnteredScore
                    : formatNumber(submission?.studentEnteredScore)}
                </View>
              </Tooltip>
            </View>
          </Flex.Item>
        </>
      )}
      <Flex.Item>{`/${assignment?.pointsPossible}`}</Flex.Item>
    </Flex>
  )
}

export default WhatIfGrade
