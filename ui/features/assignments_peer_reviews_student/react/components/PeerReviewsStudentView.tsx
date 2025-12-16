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

import React, {useState, useEffect} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Tabs} from '@instructure/ui-tabs'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import AssignmentDescription from '@canvas/assignments/react/AssignmentDescription'
import {useAssignmentQuery} from '../hooks/useAssignmentQuery'
import {useAllocatePeerReviews} from '../hooks/useAllocatePeerReviews'
import {PeerReviewSelector} from './PeerReviewSelector'
import AssignmentSubmission from './AssignmentSubmission'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints/src'
import theme from '@instructure/canvas-theme'

const I18n = createI18nScope('peer_reviews_student')

export interface PeerReviewsStudentViewProps {
  assignmentId: string
  breakpoints: Breakpoints
}

const Divider = () => (
  <View as="div" margin="medium none">
    <hr style={{border: 'none', borderBottom: `1px solid ${theme.colors.contrasts.grey1214}`}} />
  </View>
)

const PeerReviewsStudentView: React.FC<PeerReviewsStudentViewProps> = ({
  assignmentId,
  breakpoints,
}) => {
  const [selectedTab, setSelectedTab] = useState<'details' | 'submission'>('details')
  const [selectedAssessmentIndex, setSelectedAssessmentIndex] = useState(0)
  const [hasCalledAllocate, setHasCalledAllocate] = useState(false)
  const {data, isLoading, isError} = useAssignmentQuery(assignmentId)
  const {mutate: allocatePeerReviews} = useAllocatePeerReviews()
  const isMobile = breakpoints.mobileOnly

  useEffect(() => {
    if (data?.assignment && !hasCalledAllocate) {
      const assignment = data.assignment
      const assessmentRequestsCount = assignment.assessmentRequestsForCurrentUser?.length || 0
      const peerReviewsRequired = assignment.peerReviews?.count || 0

      if (assessmentRequestsCount < peerReviewsRequired) {
        setHasCalledAllocate(true)
        allocatePeerReviews({
          courseId: assignment.courseId,
          assignmentId: assignment._id,
        })
      }
    }
  }, [data, allocatePeerReviews, hasCalledAllocate])

  if (isLoading) {
    return (
      <View as="div" padding="medium" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading assignment details')} size="large" />
      </View>
    )
  }

  if (isError || !data?.assignment) {
    return (
      <View as="div" padding="medium">
        <Text color="danger">{I18n.t('Failed to load assignment details')}</Text>
      </View>
    )
  }

  const {assessmentRequestsForCurrentUser, name, dueAt, description} = data.assignment

  return (
    <>
      <View as="div">
        <Flex justifyItems="space-between" margin="0 0 medium 0">
          <Flex.Item shouldGrow={true}>
            <Flex direction="column">
              <Flex.Item>
                <Text
                  size="x-large"
                  wrap="break-word"
                  data-testid="title"
                  weight={isMobile ? 'normal' : 'light'}
                >
                  {I18n.t('%{name} Peer Review', {name: name})}
                </Text>
              </Flex.Item>
              {dueAt && (
                <Flex.Item>
                  <Text size="medium" weight="bold">
                    <FriendlyDatetime
                      data-testid="due-date"
                      prefix={I18n.t('Due:')}
                      format={I18n.t('#date.formats.full_with_weekday')}
                      dateTime={dueAt}
                    />
                  </Text>
                </Flex.Item>
              )}
            </Flex>
          </Flex.Item>
        </Flex>
        {isMobile && <Divider />}
        {data.assignment && (
          <View as="div" margin="0 0 medium 0">
            <PeerReviewSelector
              key={`${assessmentRequestsForCurrentUser?.length || 0}-peer-reviews`}
              assessmentRequests={assessmentRequestsForCurrentUser || []}
              selectedIndex={selectedAssessmentIndex}
              onSelectionChange={setSelectedAssessmentIndex}
            />
          </View>
        )}
        <Tabs
          margin="medium 0"
          onRequestTabChange={(_event, {index}) => {
            setSelectedTab(index === 0 ? 'details' : 'submission')
          }}
        >
          <Tabs.Panel
            id="assignment-details"
            renderTitle={isMobile ? I18n.t('Assignment') : I18n.t('Assignment Details')}
            isSelected={selectedTab === 'details'}
          >
            <View as="div" padding="medium 0">
              <AssignmentDescription description={description ?? undefined} />
            </View>
          </Tabs.Panel>
          <Tabs.Panel
            id="submission"
            renderTitle={isMobile ? I18n.t('Peer Review') : I18n.t('Submission')}
            isSelected={selectedTab === 'submission'}
            padding="0"
          >
            {assessmentRequestsForCurrentUser &&
              assessmentRequestsForCurrentUser[selectedAssessmentIndex]?.submission && (
                <AssignmentSubmission
                  submission={assessmentRequestsForCurrentUser[selectedAssessmentIndex].submission}
                  assignment={data.assignment}
                  isMobile={isMobile}
                />
              )}
          </Tabs.Panel>
        </Tabs>
      </View>
    </>
  )
}

export default WithBreakpoints(PeerReviewsStudentView)
