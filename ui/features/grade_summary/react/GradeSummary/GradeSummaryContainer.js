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

import React from 'react'
import {useQuery} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
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

import AssignmentTable from './AssignmentTable'
import SubmissionComment from './SubmissionComment'
import {getGradingPeriodID} from './utils'

const I18n = useI18nScope('grade_summary')

const GradeSummaryContainer = () => {
  const [showTray, setShowTray] = React.useState(false)
  const [selectedSubmission, setSelectedSubmission] = React.useState([])

  const gradingPeriod = getGradingPeriodID()

  const assignmentQuery = useQuery(ASSIGNMENTS, {
    variables: {
      courseID: ENV.course_id,
      studentID: ENV.current_user.id,
      gradingPeriodID: gradingPeriod && gradingPeriod !== '0' ? gradingPeriod : null,
    },
  })

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
        <View as="div">
          <AssignmentTable
            queryData={assignmentQuery?.data?.legacyNode}
            layout={layout}
            setShowTray={setShowTray}
            setSelectedSubmission={setSelectedSubmission}
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
      )}
    </Responsive>
  )
}

export default GradeSummaryContainer
