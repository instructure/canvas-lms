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

import React, {useState, useRef, useEffect, useCallback, useMemo} from 'react'
import AllocationRuleCard from './AllocationRuleCard'
import CreateEditAllocationRuleModal from './CreateEditAllocationRuleModal'
import {formatFullRuleDescription} from './utils/formatRuleDescription'
import {Alert} from '@instructure/ui-alerts'
import {useAllocationRules} from '../graphql/hooks/useAllocationRules'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Pagination} from '@instructure/ui-pagination'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {List} from '@instructure/ui-list'
import {debounce} from 'es-toolkit/compat'
import {useScope as createI18nScope} from '@canvas/i18n'
import pandasBalloonUrl from './images/pandasBalloon.svg'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {
  SCREENREADER_ALERT_TIMEOUT,
  SEARCH_RESULT_ANNOUNCEMENT_DELAY,
  CARD_HEIGHT,
  SEARCH_DEBOUNCE_DELAY,
} from './peerReviewConstants'

const I18n = createI18nScope('peer_review_allocation_rules_tray')

const NoResultsFound = ({searchTerm}: {searchTerm: string}) => (
  <Flex.Item as="div" padding="x-small medium" data-testid="no-search-results">
    <Text as="p" size="content">
      {I18n.t('No matching results where found for "%{searchTerm}"', {searchTerm})}
    </Text>
  </Flex.Item>
)

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
      alt=""
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
    <Spinner
      renderTitle={I18n.t('Loading allocation rules')}
      data-testid={'allocation-rules-loading-spinner'}
    />
  </Flex>
)

enum DeleteFocusType {
  CREATE_BUTTON = 'create-button',
  NEXT_RULE = 'next-rule',
  PREVIOUS_RULE = 'previous-rule',
  LAST_RULE_AFTER_PAGE_CHANGE = 'last-rule-after-page-change',
}

interface DeleteFocusInfo {
  type: DeleteFocusType
  ruleId?: string
}

const PeerReviewAllocationRulesTray = ({
  assignmentId,
  requiredPeerReviewsCount,
  isTrayOpen,
  closeTray,
  canEdit = false,
}: {
  assignmentId: string
  requiredPeerReviewsCount: number
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
  const [ruleToFocus, setRuleToFocus] = useState<string | null>(null)
  const [searchInputValue, setSearchInputValue] = useState('')
  const [searchInputErrors, setSearchInputErrors] = useState<FormMessage[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [deleteError, setDeleteError] = useState<string | null>(null)
  const [deleteFocusInfo, setDeleteFocusInfo] = useState<DeleteFocusInfo | null>(null)
  const [screenReaderAnnouncement, setScreenReaderAnnouncement] = useState('')

  const containerRef = useRef<Element | null>(null)
  const createRuleButtonRef = useRef<HTMLButtonElement | null>(null)
  const screenReaderAnnouncementTimeoutRef = useRef<NodeJS.Timeout | null>(null)

  const {rules, totalCount, loading, error, refetch} = useAllocationRules(
    assignmentId,
    currentPage,
    itemsPerPage,
    searchTerm,
  )

  const prevLoadingRef = useRef(loading)
  const prevSearchTermRef = useRef(searchTerm)
  const totalPages = totalCount ? Math.ceil(totalCount / itemsPerPage) : 0

  const handlePageChange = useCallback((newPage: number) => {
    setIsUserNavigating(true)
    setCurrentPage(newPage)
    setTimeout(() => {
      setIsUserNavigating(false)
    }, 1000)
  }, [])

  const handleRuleSave = useCallback(
    (ruleId?: string, isNewRule = true, ruleDescription?: string) => {
      if (ruleId) {
        setRuleToFocus(ruleId)
      }
      showFlashAlert({
        type: 'success',
        message: isNewRule
          ? I18n.t('New rule has been created successfully')
          : I18n.t('Rule has been edited successfully'),
      })

      // We set a delay before announcing the deletion so that it doesn't overlap with the focus change
      if (screenReaderAnnouncementTimeoutRef.current) {
        clearTimeout(screenReaderAnnouncementTimeoutRef.current)
      }
      screenReaderAnnouncementTimeoutRef.current = setTimeout(() => {
        const message = ruleDescription
          ? isNewRule
            ? I18n.t('New rule "%{rule}" has been created successfully', {rule: ruleDescription})
            : I18n.t('Rule "%{rule}" has been edited successfully', {rule: ruleDescription})
          : isNewRule
            ? I18n.t('New rule has been created successfully')
            : I18n.t('Rule has been edited successfully')
        setScreenReaderAnnouncement(message)
      }, SCREENREADER_ALERT_TIMEOUT)

      setShouldRefetch(true)
      if (!containerRef.current || isUserNavigating || loading) {
        if (preCreationTotalCount !== null) {
          const firstNewRulePage = Math.floor(preCreationTotalCount / itemsPerPage) + 1
          if (firstNewRulePage !== currentPage) {
            handlePageChange(firstNewRulePage)
          }
        }
      }
    },
    [itemsPerPage, preCreationTotalCount, currentPage, handlePageChange, isUserNavigating, loading],
  )

  const handleRuleDelete = useCallback(
    async (ruleId: string, ruleDescription?: string, error?: any) => {
      if (error) {
        const errorMessage =
          error?.message || I18n.t('An error occurred while deleting the allocation rule')
        setDeleteError(errorMessage)
        return
      }

      const deletedRuleIndex = rules.findIndex(rule => rule._id === ruleId)
      const isOnlyRule = totalCount === 1
      const isFirstRuleOnPage = deletedRuleIndex === 0

      if (isOnlyRule) {
        setDeleteFocusInfo({type: DeleteFocusType.CREATE_BUTTON})
      } else if (isFirstRuleOnPage) {
        if (rules.length > 1) {
          setDeleteFocusInfo({type: DeleteFocusType.NEXT_RULE, ruleId: rules[1]._id})
        } else {
          setDeleteFocusInfo({type: DeleteFocusType.LAST_RULE_AFTER_PAGE_CHANGE})
        }
      } else {
        setDeleteFocusInfo({
          type: DeleteFocusType.PREVIOUS_RULE,
          ruleId: rules[deletedRuleIndex - 1]._id,
        })
      }

      if (!isOnlyRule && isFirstRuleOnPage && rules.length === 1 && currentPage > 1) {
        handlePageChange(currentPage - 1)
      }

      showFlashAlert({type: 'success', message: I18n.t('Rule has been deleted successfully')})

      // We set a delay before announcing the deletion so that it doesn't overlap with the focus change
      if (screenReaderAnnouncementTimeoutRef.current) {
        clearTimeout(screenReaderAnnouncementTimeoutRef.current)
      }
      screenReaderAnnouncementTimeoutRef.current = setTimeout(() => {
        const message = ruleDescription
          ? I18n.t('Rule "%{rule}" has been deleted successfully', {rule: ruleDescription})
          : I18n.t('Rule has been deleted successfully')
        setScreenReaderAnnouncement(message)
      }, SCREENREADER_ALERT_TIMEOUT)

      setShouldRefetch(true)
    },
    [rules, currentPage, totalCount, handlePageChange],
  )

  const handleSearchInputChange = (_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setSearchInputErrors([])
    setSearchInputValue(value)
  }

  const clearSearchInput = () => {
    setSearchInputValue('')
    setSearchTerm('')
  }

  const debouncedSearch = useMemo(
    () =>
      debounce((value: string) => {
        if (value.length === 1) {
          setSearchInputErrors(prev => [
            ...prev,
            {text: I18n.t('Search term must be at least 2 characters long'), type: 'newError'},
          ])
        } else {
          setSearchTerm(value)
        }
      }, SEARCH_DEBOUNCE_DELAY),
    [setSearchTerm],
  )

  const calculateItemsPerPage = useCallback(() => {
    if (!containerRef.current || (rules.length === 0 && loading)) {
      return
    }

    let cardHeight = CARD_HEIGHT
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
  }, [itemsPerPage, totalCount, currentPage, isUserNavigating, loading, rules.length])

  const setContainerRef = useCallback(
    (el: Element | null) => {
      containerRef.current = el

      if (el && !isUserNavigating) {
        calculateItemsPerPage()
        const resizeObserver = new ResizeObserver(entries => {
          setTimeout(() => {
            if (!isUserNavigating) {
              calculateItemsPerPage()
            }
          }, 100)
        })

        resizeObserver.observe(el)

        ;(el as any)._resizeObserver = resizeObserver
      }

      if (containerRef.current && containerRef.current !== el) {
        const prevObserver = (containerRef.current as any)._resizeObserver
        if (prevObserver) {
          prevObserver.disconnect()
          delete (containerRef.current as any)._resizeObserver
        }
      }
    },
    [calculateItemsPerPage, isUserNavigating],
  )

  useEffect(() => {
    debouncedSearch(searchInputValue)
    return () => {
      debouncedSearch.cancel()
    }
  }, [searchInputValue, debouncedSearch])

  useEffect(() => {
    const wasLoading = prevLoadingRef.current && !loading
    const searchTermChanged = prevSearchTermRef.current !== searchTerm

    if (searchTerm && (wasLoading || searchTermChanged)) {
      setTimeout(() => {
        setScreenReaderAnnouncement(I18n.t('Search Results for "%{searchTerm}"', {searchTerm}))
      }, SEARCH_RESULT_ANNOUNCEMENT_DELAY)
    }

    prevLoadingRef.current = loading
    prevSearchTermRef.current = searchTerm
  }, [loading, searchTerm])

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
      const timer = setTimeout(() => {
        calculateItemsPerPage()
      }, 300)
      return () => {
        clearTimeout(timer)
      }
    }
  }, [isTrayOpen, loading, totalCount, calculateItemsPerPage, isUserNavigating])

  useEffect(() => {
    const doRefetch = async () => {
      if (shouldRefetch) {
        setShouldRefetch(false)
        const refetchResult = await refetch(currentPage)
        setTimeout(() => {
          if (ruleToFocus) {
            const editButton = document.getElementById(`edit-rule-button-${ruleToFocus}`)
            if (editButton) {
              editButton.focus()
              setRuleToFocus(null)
            }
          } else if (deleteFocusInfo) {
            if (deleteFocusInfo.type === DeleteFocusType.CREATE_BUTTON) {
              createRuleButtonRef.current?.focus()
              setDeleteFocusInfo(null)
            } else if (
              deleteFocusInfo.type === DeleteFocusType.NEXT_RULE &&
              deleteFocusInfo.ruleId
            ) {
              const editButton = document.getElementById(
                `edit-rule-button-${deleteFocusInfo.ruleId}`,
              )
              editButton?.focus()
              setDeleteFocusInfo(null)
            } else if (
              deleteFocusInfo.type === DeleteFocusType.PREVIOUS_RULE &&
              deleteFocusInfo.ruleId
            ) {
              const editButton = document.getElementById(
                `edit-rule-button-${deleteFocusInfo.ruleId}`,
              )
              editButton?.focus()
              setDeleteFocusInfo(null)
            } else if (
              deleteFocusInfo.type === DeleteFocusType.LAST_RULE_AFTER_PAGE_CHANGE &&
              refetchResult?.rules.length > 0
            ) {
              const lastRule = refetchResult.rules[refetchResult.rules.length - 1]
              const editButton = document.getElementById(`edit-rule-button-${lastRule._id}`)
              editButton?.focus()
              setDeleteFocusInfo(null)
            }
          } else if (preCreationTotalCount !== null) {
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
  }, [
    currentPage,
    shouldRefetch,
    refetch,
    rules,
    preCreationTotalCount,
    itemsPerPage,
    ruleToFocus,
    deleteFocusInfo,
  ])

  useEffect(() => {
    return () => {
      if (containerRef.current) {
        const observer = (containerRef.current as any)._resizeObserver
        if (observer) {
          observer.disconnect()
        }
      }
      if (screenReaderAnnouncementTimeoutRef.current) {
        clearTimeout(screenReaderAnnouncementTimeoutRef.current)
      }
    }
  }, [])

  useEffect(() => {
    if (deleteError) {
      const errorAlert = document.querySelector('[data-testid="delete-error-alert"]')
      if (errorAlert) {
        ;(errorAlert as HTMLElement).focus()
      }
      calculateItemsPerPage()
    }
  }, [deleteError, calculateItemsPerPage])

  useEffect(() => {
    if (currentPage > totalPages && totalPages > 0) {
      setCurrentPage(1)
    }
  }, [currentPage, totalPages])

  const clearSearchButton = () => {
    if (!searchTerm) return null

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Clear allocation rules search')}
        onClick={clearSearchInput}
        data-testid="clear-search-button"
      >
        <IconTroubleLine />
      </IconButton>
    )
  }

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
            data-testid="fetch-rules-error-alert"
          >
            {I18n.t('An error occurred while fetching allocation rules')}
          </Alert>
        </Flex.Item>
      )
    }

    if (rules.length === 0) {
      return searchTerm ? <NoResultsFound searchTerm={searchTerm} /> : <EmptyState />
    }

    return (
      <Flex direction="column" height="100%" elementRef={setContainerRef}>
        <Flex.Item shouldGrow shouldShrink>
          <List isUnstyled margin="none" data-testid="allocation-rules-list">
            {rules.map(rule => (
              <List.Item key={rule._id} aria-label={formatFullRuleDescription(rule)}>
                <View
                  as="div"
                  padding="x-small 0"
                  margin="0 medium"
                  data-testid="allocation-rule-card-wrapper"
                >
                  <AllocationRuleCard
                    rule={rule}
                    canEdit={canEdit}
                    assignmentId={assignmentId}
                    refetchRules={handleRuleSave}
                    handleRuleDelete={handleRuleDelete}
                    requiredPeerReviewsCount={requiredPeerReviewsCount}
                  />
                </View>
              </List.Item>
            ))}
          </List>
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <View data-testid="allocation-rules-tray">
      <View as="div" role="alert" aria-live="polite" data-testid="allocation-rules-tray-alert">
        <ScreenReaderContent>{screenReaderAnnouncement}</ScreenReaderContent>
      </View>
      <Tray
        label={I18n.t('Allocation Rules')}
        open={isTrayOpen}
        onDismiss={closeTray}
        placement="end"
      >
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
                  isWithinText={true}
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
                  elementRef={ref => (createRuleButtonRef.current = ref as HTMLButtonElement)}
                >
                  {I18n.t('+ Rule')}
                </Button>
              </Flex.Item>
            )}
            {(rules.length > 0 || searchInputValue) && (
              <Flex.Item as="div" padding="x-small medium">
                <TextInput
                  renderLabel={
                    <ScreenReaderContent>
                      {I18n.t('Type to search for allocation rules')}
                    </ScreenReaderContent>
                  }
                  placeholder={I18n.t('Type to search')}
                  value={searchInputValue}
                  onChange={handleSearchInputChange}
                  renderBeforeInput={<IconSearchLine inline={false} />}
                  renderAfterInput={clearSearchButton}
                  messages={searchInputErrors}
                  shouldNotWrap
                  data-testid="allocation-rules-search-input"
                />
              </Flex.Item>
            )}
            {deleteError && (
              <Flex.Item as="div" padding="x-small medium">
                <Alert
                  variant="error"
                  renderCloseButtonLabel={I18n.t('Close error alert for deleting allocation rule')}
                  data-testid="delete-error-alert"
                  liveRegion={() =>
                    document.getElementById('flash_screenreader_holder') as HTMLElement
                  }
                  onDismiss={() => setDeleteError(null)}
                >
                  {I18n.t('An error occurred while deleting the allocation rule')}
                </Alert>
              </Flex.Item>
            )}
          </Flex.Item>
          <Flex.Item size={`${CARD_HEIGHT}px`} shouldGrow shouldShrink>
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
              data-testid="allocation-rules-pagination"
            />
          </Flex.Item>
        </Flex>
      </Tray>
      <CreateEditAllocationRuleModal
        isOpen={isCreateModalOpen}
        setIsOpen={setIsCreateModalOpen}
        assignmentId={assignmentId}
        requiredPeerReviewsCount={requiredPeerReviewsCount}
        refetchRules={handleRuleSave}
      />
    </View>
  )
}

export default PeerReviewAllocationRulesTray
