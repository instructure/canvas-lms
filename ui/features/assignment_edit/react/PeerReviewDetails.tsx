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

import React, {useState, useEffect, useRef, useCallback} from 'react'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {NumberInput} from '@instructure/ui-number-input'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {canvasHighContrast, canvas} from '@instructure/ui-themes'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {createRoot} from 'react-dom/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import FormattedErrorMessage from '@canvas/assignments/react/FormattedErrorMessage'
import {usePeerReviewSettings} from './hooks/usePeerReviewSettings'

const I18n = createI18nScope('peer_review_details')
const baseTheme = ENV.use_high_contrast ? canvasHighContrast : canvas
const {colors: instui10Colors} = baseTheme
const inputOverride = {mediumHeight: '1.75rem', mediumFontSize: '0.875rem'}

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

const hasValidGroupCategory = (assignment: Assignment): boolean => {
  const groupCategoryId = assignment.groupCategoryId()
  return !!groupCategoryId && groupCategoryId !== 'blank'
}

const getIsGroupAssignment = (assignment: Assignment): boolean => {
  const hasGroupCategoryCheckbox = document.getElementById('has_group_category') as HTMLInputElement

  if (hasGroupCategoryCheckbox) {
    return hasGroupCategoryCheckbox.checked
  }

  return hasValidGroupCategory(assignment)
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

const FlexRow = ({children, ...props}: {children: React.ReactNode} & any) => (
  <Flex as="div" justifyItems="space-between" wrap="no-wrap" {...props}>
    {children}
  </Flex>
)

const LabeledInput = ({
  label,
  children,
  errorMessage,
  padding = '0',
}: {
  label: string
  children: React.ReactNode
  errorMessage?: string
  padding?: string
}) => (
  <>
    <Flex.Item as="div" padding={padding}>
      <FlexRow>
        <Flex.Item as="div" margin="0 0 small large">
          <Text size="contentSmall" weight="bold">
            {label}
          </Text>
        </Flex.Item>
        <Flex.Item as="div" padding="0 small small 0">
          {children}
        </Flex.Item>
      </FlexRow>
    </Flex.Item>
    {errorMessage && (
      <Flex.Item as="div">
        <FormattedErrorMessage message={errorMessage} margin="0 0 x-small large" />
      </Flex.Item>
    )}
  </>
)

const ToggleCheckbox = ({
  testId,
  name,
  checked,
  onChange,
  label,
  srLabel,
  id,
}: {
  testId: string
  name: string
  checked: boolean
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
  label: string
  srLabel: string
  id?: string
}) => (
  <FlexRow>
    <Flex.Item as="div" margin="0 0 0 medium" shouldGrow={true} shouldShrink={true}>
      <Text size="contentSmall" weight="bold">
        {label}
      </Text>
    </Flex.Item>
    <Flex.Item as="div" margin="0" shouldShrink={false}>
      <Checkbox
        data-testid={testId}
        name={name}
        id={id}
        variant="toggle"
        checked={checked}
        onChange={onChange}
        label={<ScreenReaderContent>{srLabel}</ScreenReaderContent>}
      />
    </Flex.Item>
  </FlexRow>
)

const SectionHeader = ({title, padding = 'small'}: {title: string; padding?: string}) => (
  <Flex.Item as="div" padding={padding}>
    <Text weight="bold" size="content">
      {title}
    </Text>
  </Flex.Item>
)

const PeerReviewDetails = ({assignment}: {assignment: Assignment}) => {
  const [peerReviewChecked, setPeerReviewChecked] = useState(assignment.peerReviews() || false)
  const [peerReviewEnabled, setPeerReviewEnabled] = useState(!assignment.moderatedGrading())
  const [isGroupAssignment, setIsGroupAssignment] = useState(hasValidGroupCategory(assignment))

  const reviewsRequiredInputRef = useRef<HTMLInputElement | null>(null)
  const pointsPerReviewInputRef = useRef<HTMLInputElement | null>(null)

  const gradingEnabled = ENV.PEER_REVIEW_GRADING_ENABLED
  const allocationEnabled = ENV.PEER_REVIEW_ALLOCATION_ENABLED

  const {
    reviewsRequired,
    handleReviewsRequiredChange,
    validateReviewsRequired,
    errorMessageReviewsRequired,
    pointsPerReview,
    handlePointsPerReviewChange,
    validatePointsPerReview,
    errorMessagePointsPerReview,
    totalPoints,
    allowPeerReviewAcrossMultipleSections,
    handleCrossSectionsCheck,
    allowPeerReviewWithinGroups,
    handleInterGroupCheck,
    usePassFailGrading,
    handleUsePassFailCheck,
    anonymousPeerReviews,
    handleAnonymityCheck,
    submissionsRequiredBeforePeerReviews,
    handleSubmissionRequiredCheck,
    resetFields,
  } = usePeerReviewSettings({
    peerReviewCount: assignment.peerReviewCount(),
    submissionRequired: assignment.peerReviewSubmissionRequired(),
    acrossSections: assignment.peerReviewAcrossSections(),
  })

  const validatePeerReviewDetails = useCallback(() => {
    let valid = true

    if (reviewsRequiredInputRef.current) {
      const err = validateReviewsRequired({
        target: reviewsRequiredInputRef.current,
      } as React.FocusEvent<HTMLInputElement>)
      if (err) valid = false
    }

    if (gradingEnabled && pointsPerReviewInputRef.current) {
      const err = validatePointsPerReview({
        target: pointsPerReviewInputRef.current,
      } as React.FocusEvent<HTMLInputElement>)
      if (err) valid = false
    }

    return valid
  }, [validateReviewsRequired, validatePointsPerReview, gradingEnabled])

  const focusOnFirstError = useCallback(() => {
    if (reviewsRequiredInputRef.current && errorMessageReviewsRequired) {
      reviewsRequiredInputRef.current.focus()
    } else if (gradingEnabled && pointsPerReviewInputRef.current && errorMessagePointsPerReview) {
      pointsPerReviewInputRef.current.focus()
    }
  }, [errorMessageReviewsRequired, errorMessagePointsPerReview, gradingEnabled])

  const handleMouseOut = (e: React.MouseEvent<HTMLDivElement>) => {
    const relatedTarget = e.relatedTarget as HTMLElement
    const currentTarget = e.currentTarget

    // Does not trigger validation if relatedTarget is within the peer review section
    if (relatedTarget && currentTarget.contains(relatedTarget)) {
      return
    }

    validatePeerReviewDetails()
  }

  useEffect(() => {
    const handlePeerReviewToggle = (event: MessageEvent) => {
      if (event.data?.subject === 'ASGMT.togglePeerReviews') {
        setPeerReviewEnabled(event.data.enabled)

        if (!event.data.enabled) {
          setPeerReviewChecked(false)
        }
      }
    }
    // Listen for peer review toggle messages from EditView
    window.addEventListener('message', handlePeerReviewToggle as EventListener)
    return () => {
      window.removeEventListener('message', handlePeerReviewToggle as EventListener)
    }
  }, [])

  useEffect(() => {
    const handleGroupCategoryChange = () => {
      setIsGroupAssignment(getIsGroupAssignment(assignment))
    }
    document.addEventListener('group_category_changed', handleGroupCategoryChange)
    return () => {
      document.removeEventListener('group_category_changed', handleGroupCategoryChange)
    }
  }, [assignment])

  useEffect(() => {
    const mountPoint = document.getElementById('peer_reviews_allocation_and_grading_details')
    if (mountPoint) {
      ;(mountPoint as any).validatePeerReviewDetails = validatePeerReviewDetails
      ;(mountPoint as any).focusOnFirstError = focusOnFirstError
    }
    return () => {
      if (mountPoint) {
        delete (mountPoint as any).validatePeerReviewDetails
        delete (mountPoint as any).focusOnFirstError
      }
    }
  }, [validatePeerReviewDetails, focusOnFirstError])

  const handlePeerReviewCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setPeerReviewChecked(e.target.checked)
    if (!e.target.checked) {
      resetFields()
    }
  }

  const advancedConfigLabel = (
    <Text size="content">{I18n.t('Advanced Peer Review Configurations')}</Text>
  )

  return (
    <Flex as="div" direction="column" width="100%">
      {peerReviewChecked && (
        <Flex.Item>
          <input
            type="hidden"
            id="peer_reviews_across_sections_checkbox_hidden"
            name="peer_reviews_across_sections_hidden"
            value={allowPeerReviewAcrossMultipleSections ? 'true' : 'false'}
          />
        </Flex.Item>
      )}
      <Flex.Item>
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
        </Flex>
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
        // There is no need to set onBlur handler on the parent div element since those events are handled in the NumberInput components
        /* eslint-disable-next-line jsx-a11y/mouse-events-have-key-events */
        <div onMouseOut={handleMouseOut}>
          <SectionHeader title={I18n.t('Review Settings')} padding="none small small small" />

          <LabeledInput
            label={I18n.t('Reviews Required*')}
            padding="x-small 0 0 0"
            errorMessage={errorMessageReviewsRequired}
          >
            <NumberInput
              id="assignment_peer_reviews_count"
              name="peer_review_count"
              data-testid="reviews-required-input"
              width="4.5rem"
              showArrows={false}
              size="medium"
              onChange={handleReviewsRequiredChange}
              onBlur={validateReviewsRequired}
              themeOverride={inputOverride}
              value={reviewsRequired}
              inputRef={(el: HTMLInputElement | null) => {
                reviewsRequiredInputRef.current = el
              }}
              renderLabel={
                <ScreenReaderContent>{I18n.t('Number of reviews required')}</ScreenReaderContent>
              }
            />
          </LabeledInput>
          {gradingEnabled && (
            <>
              <LabeledInput
                label={I18n.t('Points per Peer Review')}
                padding="x-small 0 0 0"
                errorMessage={errorMessagePointsPerReview}
              >
                <NumberInput
                  id="assignment_peer_reviews_max_input"
                  data-testid="points-per-review-input"
                  width="4.5rem"
                  showArrows={false}
                  size="medium"
                  onChange={handlePointsPerReviewChange}
                  onBlur={validatePointsPerReview}
                  themeOverride={inputOverride}
                  value={pointsPerReview}
                  inputRef={(el: HTMLInputElement | null) => {
                    pointsPerReviewInputRef.current = el
                  }}
                  renderLabel={
                    <ScreenReaderContent>
                      {I18n.t('Number of Points per Peer Review')}
                    </ScreenReaderContent>
                  }
                />
              </LabeledInput>
              <Flex.Item as="div" padding="x-small 0 medium 0">
                <FlexRow>
                  <Flex.Item as="div" margin="0 0 0 large">
                    <Text size="contentSmall" weight="bold">
                      {I18n.t('Total Points for Peer Review(s)')}
                    </Text>
                  </Flex.Item>
                  <Flex.Item as="div" padding="0 small 0 0">
                    <View as="div" padding="0 x-small 0 0">
                      <Text
                        size="contentSmall"
                        weight="bold"
                        data-testid="total-peer-review-points"
                      >
                        {totalPoints}
                      </Text>
                    </View>
                  </Flex.Item>
                </FlexRow>
              </Flex.Item>
            </>
          )}

          <Flex.Item as="div" padding="small">
            <ToggleDetails
              summary={advancedConfigLabel}
              themeOverride={{
                togglePadding: '0',
              }}
            >
              <Flex direction="column">
                <hr style={{margin: '0.5rem 0 1rem'}} aria-hidden="true"></hr>

                {allocationEnabled && (
                  <>
                    <SectionHeader title={I18n.t('Allocations')} padding="0" />
                    <Flex.Item as="div" overflowY="visible" margin="small 0">
                      <ToggleCheckbox
                        testId="across-sections-checkbox"
                        name="peer_reviews_across_sections"
                        id="peer_reviews_across_sections_checkbox"
                        checked={allowPeerReviewAcrossMultipleSections}
                        onChange={handleCrossSectionsCheck}
                        label={I18n.t('Allow peer reviews across sections')}
                        srLabel={I18n.t('Allow peer reviews to be assigned across course sections')}
                      />
                    </Flex.Item>

                    {isGroupAssignment && (
                      <Flex.Item as="div" overflowY="visible">
                        <ToggleCheckbox
                          testId="within-groups-checkbox"
                          name="peer_reviews_prevent_friends"
                          id="peer_reviews_within_groups_checkbox"
                          checked={allowPeerReviewWithinGroups}
                          onChange={handleInterGroupCheck}
                          label={I18n.t('Allow peer reviews within groups')}
                          srLabel={I18n.t('Allow peer reviews within student groups')}
                        />
                      </Flex.Item>
                    )}
                  </>
                )}

                {gradingEnabled && (
                  <>
                    <SectionHeader title={I18n.t('Grading')} padding="small 0 0 0" />

                    <Flex.Item overflowY="visible" margin="small 0">
                      <ToggleCheckbox
                        testId="pass-fail-grading-checkbox"
                        name="peer_reviews_manual_grading"
                        id="peer_reviews_pass_fail_grading_checkbox"
                        checked={usePassFailGrading}
                        onChange={handleUsePassFailCheck}
                        label={I18n.t('Use complete/incomplete instead of points for grading')}
                        srLabel={I18n.t('Use complete/incomplete instead of points for grading')}
                      />
                    </Flex.Item>
                  </>
                )}
                {allocationEnabled && (
                  <>
                    <SectionHeader title={I18n.t('Anonymity')} padding="medium 0 0 0" />

                    <Flex.Item overflowY="visible" margin="small 0">
                      <ToggleCheckbox
                        testId="anonymity-checkbox"
                        name="peer_reviews_hide_reviewer_names"
                        id="peer_reviews_anonymity_checkbox"
                        checked={anonymousPeerReviews}
                        onChange={handleAnonymityCheck}
                        label={I18n.t('Reviewers do not see who they review')}
                        srLabel={I18n.t('Reviewers do not see who they review')}
                      />
                    </Flex.Item>

                    <SectionHeader title={I18n.t('Submission required')} padding="medium 0 0 0" />

                    <Flex.Item overflowY="visible" margin="small 0">
                      <ToggleCheckbox
                        testId="submission-required-checkbox"
                        name="peer_reviews_submission_required"
                        id="peer_reviews_submission_required_checkbox"
                        checked={submissionsRequiredBeforePeerReviews}
                        onChange={handleSubmissionRequiredCheck}
                        srLabel={I18n.t('Students must submit to see peer reviews')}
                        label={I18n.t(
                          'Reviewers must submit their assignment before they can be allocated reviews',
                        )}
                      />
                    </Flex.Item>
                  </>
                )}
              </Flex>
            </ToggleDetails>
          </Flex.Item>
        </div>
      )}
    </Flex>
  )
}

export default PeerReviewDetails
