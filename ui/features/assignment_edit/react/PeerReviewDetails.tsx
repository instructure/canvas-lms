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
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {canvasHighContrast, canvas} from '@instructure/ui-themes'
import {createRoot} from 'react-dom/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import PeerReviewAllocationRulesTray from '@canvas/assignments/react/PeerReviewAllocationRulesTray'

const I18n = createI18nScope('peer_review_details')
const baseTheme = ENV.use_high_contrast ? canvasHighContrast : canvas
const {colors: instui10Colors} = baseTheme

const roots = new Map()
function createOrUpdateRoot(elementId: string, component: React.ReactNode) {
  const container = document.getElementById(elementId)
  if (!container) return

  let root = roots.get(elementId)
  if (!root) {
    root = createRoot(container)
    roots.set(elementId, root)
  }
  root.render(component)
}

export const renderPeerReviewDetails = (assignment: Assignment) => {
  const $mountPoint = document.getElementById('peer_reviews_allocation_and_grading_details')
  if ($mountPoint) {
    const queryClient = new QueryClient()
    createOrUpdateRoot(
      'peer_reviews_allocation_and_grading_details',
      <QueryClientProvider client={queryClient}>
        <PeerReviewDetails assignment={assignment} />
      </QueryClientProvider>,
    )
  }
}

const PeerReviewDetails = ({assignment}: {assignment: Assignment}) => {
  const [peerReviewChecked, setPeerReviewChecked] = useState(assignment.peerReviews() || false)
  const [peerReviewEnabled, setPeerReviewEnabled] = useState(!assignment.moderatedGrading())
  const [showRuleTray, setShowRuleTray] = useState(false)

  useEffect(() => {
    const handlePeerReviewToggle = (event: MessageEvent) => {
      if (event.data?.subject === 'ASGMT.togglePeerReviews') {
        setPeerReviewEnabled(event.data.enabled)

        if (!event.data.enabled) {
          setPeerReviewChecked(false)
          setShowRuleTray(false)
        }
      }
    }

    // Listen for peer review toggle messages from EditView
    window.addEventListener('message', handlePeerReviewToggle as EventListener)
    return () => {
      window.removeEventListener('message', handlePeerReviewToggle as EventListener)
    }
  }, [])

  const handlePeerReviewCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPeerReviewChecked(e.target.checked)
    if (!e.target.checked) {
      setShowRuleTray(false)
    }
  }

  const advancedConfigLabel = (
    <Text size="content">{I18n.t('Advanced Peer Review Configurations')}</Text>
  )

  return (
    <Flex direction="column" padding="medium 0 medium x-small">
      <Flex.Item as="div" padding="xx-small">
        <Checkbox
          id="assignment_peer_reviews_checkbox"
          name="peer_reviews"
          checked={peerReviewChecked}
          disabled={!peerReviewEnabled}
          onChange={handlePeerReviewCheck}
          label={I18n.t('Require Peer Reviews')}
          size="small"
          themeOverride={{
            checkedBackground: instui10Colors.dataVisualization.ocean40Secondary,
            checkedBorderColor: 'white',
          }}
          data-testid="peer-review-checkbox"
        />
      </Flex.Item>
      {!peerReviewEnabled && (
        <Flex.Item as="div" padding="0 0 xx-small medium">
          <View as="div" margin="0 0 0 xx-small">
            <Text size="contentSmall">
              {I18n.t('Peer reviews cannot be enabled for assignments with moderated grading.')}
            </Text>
          </View>
        </Flex.Item>
      )}
      {peerReviewChecked && (
        <>
          <Flex.Item as="div" padding="xx-small">
            <Text weight="bold" size="content">
              {I18n.t('Review Settings')}
            </Text>
          </Flex.Item>
          <Flex.Item as="div" padding="xx-small">
            <ToggleDetails
              summary={advancedConfigLabel}
              themeOverride={{
                togglePadding: '0',
              }}
            >
              <Flex direction="column">
                <hr style={{margin: '0.5rem 0 1rem'}} aria-hidden="true" />
                <Text weight="bold" size="content">
                  {I18n.t('Allocations')}
                </Text>
                <Flex.Item padding="small 0 small medium">
                  <Link
                    variant="standalone"
                    renderIcon={<IconExternalLinkLine />}
                    onClick={() => setShowRuleTray(true)}
                    href="#"
                  >
                    <Text size="content">{I18n.t('Customize Allocations')}</Text>
                  </Link>
                </Flex.Item>
              </Flex>
            </ToggleDetails>
          </Flex.Item>
          <Flex.Item>
            <PeerReviewAllocationRulesTray
              assignmentId={assignment.getId()}
              // For now, always allow editing of allocation rules from the details view.
              // Once we expose proper permissions in the API, we can use that to determine if editing
              // https://instructure.atlassian.net/browse/EGG-1709
              canEdit={true}
              isTrayOpen={showRuleTray}
              closeTray={() => setShowRuleTray(false)}
            />
          </Flex.Item>
        </>
      )}
    </Flex>
  )
}

export default PeerReviewDetails
