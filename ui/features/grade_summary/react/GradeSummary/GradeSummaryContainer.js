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

import React, {useContext, useState, useEffect} from 'react'
import {useQuery, useMutation} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Responsive} from '@instructure/ui-responsive'
import {Spinner} from '@instructure/ui-spinner'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'

import {ASSIGNMENTS} from '../../graphql/queries'
import {UPDATE_SUBMISSIONS_READ_STATE} from '../../graphql/Mutations'

import AssignmentTable from './AssignmentTable'
import SubmissionComment from './SubmissionComment'
import {getGradingPeriodID} from './utils'
import {GradeSummaryContext} from './context'

const I18n = useI18nScope('grade_summary')

const GradeSummaryContainer = () => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [showTray, setShowTray] = useState(false)
  const [selectedSubmission, setSelectedSubmission] = useState('')
  const [submissionIdsForUpdate, setSubmissionIdsForUpdate] = useState([])

  const gradingPeriod = getGradingPeriodID()

  const variables = {
    courseID: ENV.course_id,
  }

  if (gradingPeriod !== undefined) {
    variables.gradingPeriodID = gradingPeriod && gradingPeriod !== '0' ? gradingPeriod : null
  }

  const assignmentQuery = useQuery(ASSIGNMENTS, {
    variables,
  })

  const [readStateChangeSubmission] = useMutation(UPDATE_SUBMISSIONS_READ_STATE, {
    onCompleted(data) {
      if (data.updateSubmissionsReadState.errors) {
        setOnFailure(I18n.t('Read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Read state Changed!',
              other: 'Read states Changed!',
            },
            {count: '1000'}
          )
        )
        setSubmissionIdsForUpdate([])
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    },
  })

  useEffect(() => {
    const interval = setInterval(() => {
      if (submissionIdsForUpdate.length > 0) {
        readStateChangeSubmission({
          variables: {
            submissionIds: submissionIdsForUpdate,
            read: true,
          },
        })
      }
    }, 3000)

    return () => clearInterval(interval)
  }, [submissionIdsForUpdate, readStateChangeSubmission])

  if (assignmentQuery.loading) {
    return (
      <Flex alignItems="center" justifyItems="center" width="100%">
        <Flex.Item>
          <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
        </Flex.Item>
      </Flex>
    )
  }

  if (assignmentQuery.error || !assignmentQuery?.data?.legacyNode) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Grade Summary initial query error')}
        errorCategory={I18n.t('Grade Summary Error Page')}
      />
    )
  }

  const gradeSummaryContext = {
    assignmentSortBy: document.querySelector('#assignment_sort_order_select_menu').value,
  }

  const handleReadStateChange = submissionID => {
    if (!submissionID) return
    const arr = [...submissionIdsForUpdate, submissionID]
    setSubmissionIdsForUpdate(
      arr.filter(
        (item, index) => item !== null && item !== undefined && arr.indexOf(item) === index
      )
    )
  }

  const renderCloseButton = () => {
    return (
      <Flex>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Heading>Submission Comments</Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            onClick={() => setShowTray(false)}
          />
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <Responsive
      query={{
        small: {maxWidth: '40rem'},
        large: {minWidth: '41rem'},
      }}
      props={{
        small: {layout: 'stacked'},
        large: {layout: 'fixed'},
      }}
    >
      {({layout}) => (
        <GradeSummaryContext.Provider value={gradeSummaryContext}>
          <View as="div">
            <AssignmentTable
              queryData={assignmentQuery?.data?.legacyNode}
              layout={layout}
              setShowTray={setShowTray}
              setSelectedSubmission={setSelectedSubmission}
              handleReadStateChange={handleReadStateChange}
            />
            <Tray
              label={I18n.t('Submission Comments Tray')}
              open={showTray}
              onDismiss={() => {
                setShowTray(false)
              }}
              size="medium"
              placement="end"
            >
              <View as="div" padding="medium">
                {renderCloseButton()}
                {selectedSubmission?.commentsConnection?.nodes?.map(comment => {
                  return <SubmissionComment comment={comment} key={comment?._id} />
                })}
              </View>
            </Tray>
          </View>
        </GradeSummaryContext.Provider>
      )}
    </Responsive>
  )
}

export default GradeSummaryContainer
