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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Tabs} from '@instructure/ui-tabs'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import AssignmentDescription from '@canvas/assignments/react/AssignmentDescription'
import {useAssignmentQuery} from '../hooks/useAssignmentQuery'
import {PeerReviewSelector} from './PeerReviewSelector'

const I18n = createI18nScope('peer_reviews_student')

interface PeerReviewsStudentViewProps {
  assignmentId: string
}

const PeerReviewsStudentView: React.FC<PeerReviewsStudentViewProps> = ({assignmentId}) => {
  const [selectedTab, setSelectedTab] = useState<'details' | 'submission'>('details')
  const [selectedAssessmentIndex, setSelectedAssessmentIndex] = useState(0)
  const {data, isLoading, isError} = useAssignmentQuery(assignmentId)

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

  const assignment = data.assignment

  return (
    <View as="div" padding="medium">
      <Flex justifyItems="space-between" margin="0 0 medium 0">
        <Flex.Item shouldGrow={true}>
          <Flex direction="column">
            <Flex.Item>
              <Text size="x-large" wrap="break-word" data-testid="title" weight="light">
                {I18n.t('%{name} Peer Review', {name: assignment.name})}
              </Text>
            </Flex.Item>
            {assignment.dueAt && (
              <Flex.Item>
                <Text size="medium" weight="bold">
                  <FriendlyDatetime
                    data-testid="due-date"
                    prefix={I18n.t('Due:')}
                    format={I18n.t('#date.formats.full_with_weekday')}
                    dateTime={assignment.dueAt}
                  />
                </Text>
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
      </Flex>
      {assignment && (
        <View as="div" margin="0 0 medium 0">
          <PeerReviewSelector
            assessmentRequests={assignment.assessmentRequestsForCurrentUser || []}
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
          renderTitle={I18n.t('Assignment Details')}
          isSelected={selectedTab === 'details'}
        >
          <View as="div" padding="medium 0">
            <AssignmentDescription description={assignment.description ?? undefined} />
          </View>
        </Tabs.Panel>

        <Tabs.Panel
          id="submission"
          renderTitle={I18n.t('Submission')}
          isSelected={selectedTab === 'submission'}
        ></Tabs.Panel>
      </Tabs>
    </View>
  )
}

export default PeerReviewsStudentView
