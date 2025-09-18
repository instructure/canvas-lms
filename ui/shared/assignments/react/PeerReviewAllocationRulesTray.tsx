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

import React, {useState, useRef, useEffect, useCallback} from 'react'
import AllocationRuleCard, {AllocationRuleType} from './AllocationRuleCard'
import CreateEditAllocationRuleModal from './CreateEditAllocationRuleModal'
import {Alert} from '@instructure/ui-alerts'
import {useAllocationRules} from '../graphql/hooks/useAllocationRules'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Pagination} from '@instructure/ui-pagination'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import pandasBalloonUrl from './images/pandasBalloon.svg'

const I18n = createI18nScope('peer_review_allocation_rules_tray')

const EmptyState = () => (
  <Flex
    direction="column"
    alignItems="center"
    justifyItems="center"
    padding="medium"
    textAlign="center"
    margin="large 0 0 0"
  >
    <Img
      src={pandasBalloonUrl}
      alt="Pandas Balloon"
      style={{width: '160px', height: 'auto', marginBottom: '1rem'}}
    />
    <Heading level="h3" margin="medium 0">
      {I18n.t('Create New Rules')}
    </Heading>
    <Text as="p" size="content">
      {I18n.t(
        'Allocation of peer reviews happens behind the scenes and is optimized for a fair distribution to all participants.',
      )}
    </Text>
    <Text as="p" size="content">
      {I18n.t('You can create rules that support your learning goals for the assignment.')}
    </Text>
    <Text size="content">
      {/* TODO: Replace with link to documentation in EGG-1588 */}
      <Link href="#" isWithinText={false} target="_blank">
        {I18n.t('Learn more about how peer review allocation works.')}
      </Link>
    </Text>
  </Flex>
)

const LoadingState = () => (
  <Flex direction="column" alignItems="center" padding="large">
    <Spinner renderTitle={I18n.t('Loading allocation rules')} />
  </Flex>
)

const PeerReviewAllocationRulesTray = ({
  assignmentId,
  isTrayOpen,
  closeTray,
  canEdit = false,
}: {
  assignmentId: string
  isTrayOpen: boolean
  closeTray: () => void
  canEdit: boolean
}): React.ReactElement => {
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false)
  const [currentPage, setCurrentPage] = useState(1)
  const [itemsPerPage, setItemsPerPage] = useState(4)
  const [shouldRefetch, setShouldRefetch] = useState(false)
  const [preCreationTotalCount, setPreCreationTotalCount] = useState<number | null>(null)
  const [isUserNavigating, setIsUserNavigating] = useState(false)

  const containerRef = useRef<Element | null>(null)

  const {rules, totalCount, loading, error, refetch} = useAllocationRules(
    assignmentId,
    currentPage,
    itemsPerPage,
  )

  const totalPages = totalCount ? Math.ceil(totalCount / itemsPerPage) : 0
  const formattedRules: AllocationRuleType[] = rules.map(
    (rule): AllocationRuleType => ({
      id: rule._id,
      reviewer: {
        _id: rule.assessor._id,
        name: rule.assessor.name,
      },
      reviewee: {
        _id: rule.assessee._id,
        name: rule.assessee.name,
      },
      mustReview: rule.mustReview,
      reviewPermitted: rule.reviewPermitted,
      appliesToReviewer: rule.appliesToAssessor,
    }),
  )

  const handlePageChange = useCallback((newPage: number) => {
    setIsUserNavigating(true)
    setCurrentPage(newPage)
    setTimeout(() => {
      setIsUserNavigating(false)
    }, 1000)
  }, [])

  const handleRuleCreated = useCallback(() => {
    if (preCreationTotalCount !== null) {
      const firstNewRulePage = Math.floor(preCreationTotalCount / itemsPerPage) + 1
      setShouldRefetch(true)
      if (firstNewRulePage !== currentPage) {
        handlePageChange(firstNewRulePage)
      }
    }
  }, [itemsPerPage, preCreationTotalCount, currentPage, handlePageChange])

  const calculateItemsPerPage = useCallback(() => {
    if (!containerRef.current || isUserNavigating || loading) {
      return
    }

    let cardHeight = 120
    const cardElement = containerRef.current.querySelector(
      '[data-testid="allocation-rule-card-wrapper"]',
    )
    if (cardElement) {
      cardHeight = cardElement.clientHeight
    }

    const containerHeight = containerRef.current.clientHeight
    const maxCards = Math.floor(containerHeight / cardHeight)
    const newItemsPerPage = Math.max(1, maxCards)

    if (newItemsPerPage !== itemsPerPage) {
      setItemsPerPage(newItemsPerPage)
      const newTotalPages = totalCount ? Math.ceil(totalCount / newItemsPerPage) : 0
      if (currentPage > newTotalPages && newTotalPages > 0 && !isUserNavigating) {
        setCurrentPage(newTotalPages)
      }
    }
  }, [itemsPerPage, totalCount, currentPage, isUserNavigating, loading])

  useEffect(() => {
    const container = containerRef.current
    if (!container) return

    const resizeObserver = new ResizeObserver(() => {
      setTimeout(() => {
        if (!isUserNavigating) {
          calculateItemsPerPage()
        }
      }, 100)
    })

    resizeObserver.observe(container)

    return () => {
      resizeObserver.disconnect()
    }
  }, [calculateItemsPerPage, isUserNavigating])

  const setContainerRef = useCallback(
    (el: Element | null) => {
      containerRef.current = el

      if (el && !isUserNavigating) {
        calculateItemsPerPage()
      }
    },
    [calculateItemsPerPage, isUserNavigating],
  )

  useEffect(() => {
    if (totalCount !== null) {
      setPreCreationTotalCount(totalCount)
    } else if (totalCount === null && !loading) {
      setPreCreationTotalCount(0)
    }
  }, [totalCount, preCreationTotalCount, loading])

  useEffect(() => {
    if (
      isTrayOpen &&
      !loading &&
      totalCount !== null &&
      containerRef.current &&
      !isUserNavigating
    ) {
      const timer = setTimeout(calculateItemsPerPage, 300)
      return () => clearTimeout(timer)
    }
  }, [isTrayOpen, loading, totalCount, calculateItemsPerPage, isUserNavigating])

  useEffect(() => {
    const doRefetch = async () => {
      if (shouldRefetch) {
        setShouldRefetch(false)
        await refetch(currentPage)
        setTimeout(() => {
          if (preCreationTotalCount !== null) {
            const ruleIndexOnPage = preCreationTotalCount % itemsPerPage
            const ruleCards = document.querySelectorAll(
              '[data-testid="allocation-rule-card-wrapper"]',
            )
            const targetCard = ruleCards[ruleIndexOnPage]
            if (targetCard) {
              const editButton = targetCard.querySelector('button[id^="edit-rule-button-"]')
              if (editButton) {
                ;(editButton as HTMLElement).focus()
              }
            }
          }
        }, 300)
      }
    }
    doRefetch()
  }, [currentPage, shouldRefetch, refetch, rules, preCreationTotalCount, itemsPerPage])

  const renderContent = () => {
    if (loading) return <LoadingState />

    if (error) {
      return (
        <Flex.Item as="div" padding="x-small medium">
          <Alert
            variant="error"
            renderCloseButtonLabel={I18n.t('Close error alert for allocation rule tray')}
            margin="0 0 medium 0"
            variantScreenReaderLabel={I18n.t('Error, ')}
          >
            {I18n.t('An error occurred while fetching allocation rules')}
          </Alert>
        </Flex.Item>
      )
    }

    if (formattedRules.length === 0) return <EmptyState />

    return (
      <Flex direction="column" height="100%" elementRef={setContainerRef}>
        <Flex.Item shouldGrow shouldShrink>
          {formattedRules.map(rule => (
            <Flex.Item
              as="div"
              padding="x-small medium"
              key={rule.id}
              data-testid="allocation-rule-card-wrapper"
            >
              <AllocationRuleCard rule={rule} canEdit={canEdit} />
            </Flex.Item>
          ))}
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <View data-testid="allocation-rules-tray">
      <Tray label={I18n.t('Allocation Rules')} open={isTrayOpen} placement="end">
        <Flex direction="column" height="100vh">
          <Flex.Item>
            <Flex as="div" padding="medium">
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <Heading level="h3" as="h2">
                  {I18n.t('Allocation Rules')}
                </Heading>
              </Flex.Item>
              <Flex.Item>
                <CloseButton
                  data-testid="allocation-rules-tray-close-button"
                  placement="end"
                  offset="medium"
                  screenReaderLabel={I18n.t('Close Allocation Rules Tray')}
                  size="small"
                  onClick={closeTray}
                />
              </Flex.Item>
            </Flex>
            <Flex.Item as="div" padding="xx-small medium x-small medium">
              <Text>
                {I18n.t('For peer review configuration return to ')}
                <Link
                  isWithinText={false}
                  href={`/courses/${ENV.COURSE_ID}/assignments/${assignmentId}/edit?scrollTo=assignment_peer_reviews_fields`}
                >
                  {I18n.t('Edit Assignment')}
                </Link>
                .
              </Text>
            </Flex.Item>
            {canEdit && (
              <Flex.Item as="div" padding="x-small medium">
                <Button
                  color="primary"
                  onClick={() => setIsCreateModalOpen(true)}
                  data-testid="add-rule-button"
                >
                  {I18n.t('+ Rule')}
                </Button>
              </Flex.Item>
            )}
          </Flex.Item>
          <Flex.Item shouldGrow shouldShrink>
            {renderContent()}
          </Flex.Item>
          <Flex.Item as="div" padding="small medium">
            <Pagination
              as="nav"
              variant="compact"
              labelNext={I18n.t('Next Allocation Rules Page: Page %{page}', {
                page: currentPage + 1,
              })}
              labelPrev={I18n.t('Previous Allocation Rules Page: Page %{page}', {
                page: currentPage - 1,
              })}
              currentPage={currentPage}
              totalPageNumber={totalPages}
              onPageChange={handlePageChange}
            />
          </Flex.Item>
        </Flex>
      </Tray>
      <CreateEditAllocationRuleModal
        isOpen={isCreateModalOpen}
        setIsOpen={setIsCreateModalOpen}
        assignmentId={assignmentId}
        courseId={ENV.COURSE_ID}
        refetchRules={handleRuleCreated}
      />
    </View>
  )
}

export default PeerReviewAllocationRulesTray
