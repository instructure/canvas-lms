/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useMemo, memo, useRef, useState} from 'react'
import {Mask} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {Button} from '@instructure/ui-buttons'
import {ApplyLocale} from '@instructure/ui-i18n'
import {uid} from '@instructure/uid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {
  AssigneeOption,
  BaseDateDetails,
  DateLockTypes,
  exportedOverride,
  FetchDueDatesResponse,
  ItemAssignToCardSpec,
} from './types'
import ItemAssignToCard, {type ItemAssignToCardRef} from './ItemAssignToCard'
import {getOverriddenAssignees, itemTypeToApiURL} from '../../utils/assignToHelper'
import {getEveryoneOption, ItemAssignToTrayProps} from './ItemAssignToTray'

const I18n = useI18nScope('differentiated_modules')

export interface ItemAssignToTrayContentProps
  extends Omit<ItemAssignToTrayProps, 'iconType' | 'itemName'> {
  assignToCards: ItemAssignToCardSpec[]
  setAssignToCards: (cards: ItemAssignToCardSpec[]) => void
  blueprintDateLocks?: DateLockTypes[]
  setBlueprintDateLocks: (locks?: DateLockTypes[]) => void
  handleDismiss: () => void
  hasModuleOverrides: boolean
  setHasModuleOverrides: (state: boolean) => void
  setModuleAssignees: (assignees: string[]) => void
  disabledOptionIds: string[]
  setDisabledOptionIds: (options: string[]) => void
  defaultGroupCategoryId: string | null
  initialLoadRef: React.MutableRefObject<boolean>
  allOptions: AssigneeOption[]
  isLoadingAssignees: boolean
  isLoading: boolean
  loadedAssignees: boolean
  setSearchTerm: (term: string) => void
  everyoneOption: AssigneeOption
  setGroupCategoryId: (id: string | null) => void
  setOverridesFetched: (flag: boolean) => void
  cardsRefs: React.MutableRefObject<{
    [cardId: string]: ItemAssignToCardRef
  }>
  postToSIS?: boolean
}

function makeCardId(): string {
  return uid('assign-to-card', 3)
}

const ItemAssignToCardMemo = memo(
  props => {
    return <ItemAssignToCard {...props} />
  },
  (prevProps: ItemAssignToCardSpec, nextProps: ItemAssignToCardSpec) => {
    return (
      prevProps.everyoneOption.value === nextProps.everyoneOption.value &&
      prevProps.selectedAssigneeIds === nextProps.selectedAssigneeIds &&
      // prevProps.disabledOptionIds === nextProps.disabledOptionIds &&
      prevProps.highlightCard === nextProps.highlightCard &&
      prevProps.isOpen === nextProps.isOpen &&
      prevProps.due_at === nextProps.due_at &&
      prevProps.original_due_at === nextProps.original_due_at &&
      prevProps.unlock_at === nextProps.unlock_at &&
      prevProps.lock_at === nextProps.lock_at &&
      prevProps.reply_to_topic_due_at === nextProps.reply_to_topic_due_at &&
      prevProps.required_replies_due_at === nextProps.required_replies_due_at &&
      prevProps.removeDueDateInput === nextProps.removeDueDateInput &&
      prevProps.isCheckpointed === nextProps.isCheckpointed &&
      prevProps.courseId === nextProps.courseId &&
      prevProps.contextModuleId === nextProps.contextModuleId &&
      prevProps.contextModuleName === nextProps.contextModuleName
    )
  }
)

const ItemAssignToTrayContent = ({
  open,
  assignToCards,
  initialLoadRef,
  setAssignToCards,
  courseId,
  itemType,
  itemContentId,
  initHasModuleOverrides,
  locale,
  timezone,
  defaultCards,
  defaultDisabledOptionIds = [],
  onAddCard,
  onAssigneesChange,
  onDatesChange,
  onCardRemove,
  defaultSectionId,
  removeDueDateInput = false,
  isCheckpointed = false,
  onInitialStateSet,
  blueprintDateLocks,
  setBlueprintDateLocks,
  handleDismiss,
  cardsRefs,
  hasModuleOverrides,
  setHasModuleOverrides,
  setModuleAssignees,
  disabledOptionIds,
  setDisabledOptionIds,
  defaultGroupCategoryId,
  allOptions,
  setSearchTerm,
  isLoadingAssignees,
  isLoading,
  loadedAssignees,
  everyoneOption,
  setGroupCategoryId,
  setOverridesFetched,
  postToSIS = false,
}: ItemAssignToTrayContentProps) => {
  const [initialCards, setInitialCards] = useState<ItemAssignToCardSpec[]>([])
  const [fetchInFlight, setFetchInFlight] = useState(false)

  const lastPerformedAction = useRef<{action: 'add' | 'delete'; index?: number} | null>(null)
  const addCardButtonRef = useRef<Element | null>(null)

  useEffect(() => {
    if (
      defaultCards === undefined ||
      !itemContentId ||
      itemType !== 'assignment' ||
      initialLoadRef.current
    )
      return

    setFetchInFlight(true)
    doFetchApi({
      path: itemTypeToApiURL(courseId, itemType, itemContentId),
      params: {per_page: 100},
    })
      .then((response: FetchDueDatesResponse) => {
        const dateDetailsApiResponse = response.json
        setBlueprintDateLocks(dateDetailsApiResponse.blueprint_date_locks)
      })
      .catch(() => {
        showFlashError()()
        handleDismiss()
      })
      .finally(() => {
        setFetchInFlight(false)
        initialLoadRef.current = true
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    setGroupCategoryId(defaultGroupCategoryId)
  }, [defaultGroupCategoryId, setGroupCategoryId])

  useEffect(() => {
    if (assignToCards.length === 0 && !lastPerformedAction.current) return
    const action = lastPerformedAction.current?.action
    const index = lastPerformedAction.current?.index || 0
    // If only a card remains, we should focus the add button
    const shouldFocusAddButton = action === 'delete' && assignToCards.length <= 1
    let focusIndex
    if (shouldFocusAddButton && addCardButtonRef?.current instanceof HTMLButtonElement) {
      addCardButtonRef.current.disabled = false // so it can be focused
      addCardButtonRef.current.focus()
    } else if (action === 'add') {
      // Focus the last card
      focusIndex = assignToCards.length - 1
    } else if (action === 'delete') {
      // Focus the previous card
      focusIndex = index <= 0 ? 0 : index - 1
    }
    if (focusIndex !== undefined) {
      const card = assignToCards.at(focusIndex)
      if (card) {
        const cardRef = cardsRefs.current[card.key]
        cardRef?.focusDeleteButton()
      }
    }
    lastPerformedAction.current = null
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [assignToCards.length])

  useEffect(() => {
    if (defaultCards !== undefined) {
      setAssignToCards(defaultCards)
    }
    setOverridesFetched(defaultCards !== undefined)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(defaultCards)])

  useEffect(() => {
    setDisabledOptionIds(defaultDisabledOptionIds)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(defaultDisabledOptionIds)])

  useEffect(() => {
    if (defaultCards !== undefined || itemContentId === undefined) {
      if (initHasModuleOverrides !== undefined && hasModuleOverrides !== undefined) {
        setHasModuleOverrides(initHasModuleOverrides)
      }
      return
    }
    setFetchInFlight(true)
    doFetchApi({
      path: itemTypeToApiURL(courseId, itemType, itemContentId),
      params: {per_page: 100},
    })
      .then((response: FetchDueDatesResponse) => {
        // TODO: exhaust pagination
        const dateDetailsApiResponse = response.json
        const overrides = dateDetailsApiResponse.overrides
        const overriddenTargets = getOverriddenAssignees(overrides)
        delete dateDetailsApiResponse.overrides
        const baseDates: BaseDateDetails = dateDetailsApiResponse
        const onlyOverrides = !dateDetailsApiResponse.visible_to_everyone
        const allModuleAssignees: string[] = []
        const hasModuleOverride = overrides?.some(override => override.context_module_id)
        const hasCourseOverride = overrides?.some(override => override.course_id)

        const cards: ItemAssignToCardSpec[] = []
        const selectedOptionIds: string[] = []
        if (!onlyOverrides && !hasCourseOverride) {
          // only add the regular everyone card if there isn't a course override
          const cardId = makeCardId()
          const selectedOption = [getEveryoneOption(assignToCards.length > 1).id]
          cards.push({
            key: cardId,
            isValid: true,
            hasAssignees: true,
            due_at: baseDates.due_at,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            original_due_at: baseDates.due_at,
            unlock_at: baseDates.unlock_at,
            lock_at: baseDates.lock_at,
            selectedAssigneeIds: selectedOption,
            overrideId: dateDetailsApiResponse.id,
          })
          selectedOptionIds.push(...selectedOption)
        }
        if (overrides?.length) {
          overrides.forEach(override => {
            // if an override is unassigned, we don't need to show a card for it
            if (override.unassign_item) {
              return
            }
            // need to get any module assignees before we start filtering out hidden module cards
            if (override.context_module_id) {
              if (override.course_section_id) {
                allModuleAssignees.push(`section-${override.course_section_id}`)
              }
              if (override.student_ids) {
                allModuleAssignees.push(...override.student_ids.map(id => `student-${id}`))
              }
            }
            let removeCard = false
            let filteredStudents = override.student_ids
            if (override.context_module_id && override.student_ids) {
              filteredStudents = filteredStudents?.filter(
                id => !overriddenTargets?.students?.includes(id)
              )
              removeCard = override.student_ids?.length > 0 && filteredStudents?.length === 0
            }
            const studentOverrides =
              filteredStudents?.map(studentId => `student-${studentId}`) ?? []
            const defaultOptions = studentOverrides
            if (override.noop_id) {
              defaultOptions.push('mastery_paths')
            }
            if (override.course_section_id) {
              defaultOptions.push(`section-${override.course_section_id}`)
            }
            if (override.course_id) {
              defaultOptions.push('everyone')
            }
            if (override.group_id) {
              defaultOptions.push(`group-${override.group_id}`)
            }
            removeCard = removeCard || override.student_ids?.length === 0
            if (
              removeCard ||
              (override.context_module_id &&
                override?.course_section_id &&
                overriddenTargets?.sections?.includes(override?.course_section_id))
            ) {
              return
            }
            const cardId = makeCardId()
            cards.push({
              key: cardId,
              isValid: true,
              hasAssignees: true,
              due_at: override.due_at,
              reply_to_topic_due_at: null,
              required_replies_due_at: null,
              original_due_at: override.due_at,
              unlock_at: override.unlock_at,
              lock_at: override.lock_at,
              selectedAssigneeIds: defaultOptions,
              defaultOptions,
              overrideId: override.id,
              contextModuleId: override.context_module_id,
              contextModuleName: override.context_module_name,
            })
            selectedOptionIds.push(...defaultOptions)
          })
        }
        setModuleAssignees(allModuleAssignees)
        setHasModuleOverrides(hasModuleOverride || false)
        setGroupCategoryId(dateDetailsApiResponse.group_category_id)
        setOverridesFetched(true)
        setBlueprintDateLocks(dateDetailsApiResponse.blueprint_date_locks)
        setDisabledOptionIds(selectedOptionIds)
        setInitialCards(cards)
        onInitialStateSet?.(cards)
        setAssignToCards(cards)
      })
      .catch(() => {
        showFlashError()()
        handleDismiss()
      })
      .finally(() => {
        setFetchInFlight(false)
        initialLoadRef.current = true
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, itemContentId, itemType, JSON.stringify(defaultCards)])

  const handleAddCard = () => {
    if (onAddCard) {
      onAddCard()
      return
    }
    const cardId = makeCardId()
    const cards: ItemAssignToCardSpec[] = [
      ...assignToCards,
      {
        key: cardId,
        isValid: true,
        hasAssignees: false,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        due_at: null,
        unlock_at: null,
        lock_at: null,
        contextModuleId: null,
        contextModuleName: null,
        selectedAssigneeIds: [] as string[],
      } as ItemAssignToCardSpec,
    ]
    lastPerformedAction.current = {action: 'add'}
    setAssignToCards(cards)
  }

  const handleDeleteCard = useCallback(
    (cardId: string) => {
      const cardIndex = assignToCards.findIndex(card => card.key === cardId)
      const cardSelection = assignToCards.at(cardIndex)?.selectedAssigneeIds ?? []
      const newDisabled = disabledOptionIds.filter(id => !cardSelection.includes(id))
      const cards = assignToCards.filter(({key}) => key !== cardId)
      lastPerformedAction.current = {action: 'delete', index: cardIndex}
      setAssignToCards(cards)
      setDisabledOptionIds(newDisabled)
      onCardRemove?.(cardId)
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [assignToCards, disabledOptionIds, onCardRemove, setAssignToCards]
  )

  const handleCardValidityChange = useCallback(
    (cardId: string, isValid: boolean) => {
      const priorCard = assignToCards.find(card => card.key === cardId)
      if (priorCard) {
        const validityChanged = priorCard.isValid !== isValid
        if (!validityChanged) {
          return
        }
      }
      const cards = assignToCards.map(card => (card.key === cardId ? {...card, isValid} : card))
      setAssignToCards(cards)
    },
    [assignToCards, setAssignToCards]
  )

  const handleCustomAssigneesChange = useCallback(
    (cardId: string, assignees: AssigneeOption[], deletedAssignees: string[]) => {
      const newSelectedOption = assignees.filter(
        assignee => !disabledOptionIds.includes(assignee.id)
      )[0]
      const idData = newSelectedOption?.id?.split('-')
      const isEveryoneOption = newSelectedOption?.id === everyoneOption.id
      const parsedCard =
        newSelectedOption === undefined
          ? ({} as exportedOverride)
          : ({
              id: isEveryoneOption ? defaultSectionId : idData[1],
              name: newSelectedOption.value,
            } as exportedOverride)

      if (newSelectedOption?.id === everyoneOption.id) {
        if (hasModuleOverrides) {
          parsedCard.course_id = 'everyone'
        } else {
          parsedCard.course_section_id = defaultSectionId
        }
      } else if (parsedCard.id && idData[0] === 'section') {
        parsedCard.course_section_id = idData[1]
      } else if (parsedCard.id && idData[0] === 'student') {
        parsedCard.short_name = newSelectedOption.value
      } else if (parsedCard.id && idData[0] === 'group') {
        parsedCard.group_id = idData[1]
        parsedCard.group_category_id = newSelectedOption.groupCategoryId
      } else if (idData && idData[0] === 'mastery_paths') {
        parsedCard.noop_id = '1'
      }

      const parsedDeletedCard = deletedAssignees.map(id => {
        const card = allOptions.find(a => a.id === id)
        const data = card?.id?.split('-')
        const deleted = {name: card?.value, type: data?.[0]} as exportedOverride

        if (id === everyoneOption.id) {
          deleted.course_section_id = defaultSectionId
        } else if (data?.[0] === 'section') {
          deleted.course_section_id = data[1]
        } else if (data?.[0] === 'student') {
          deleted.short_name = card?.value
          deleted.student_id = data[1]
        } else if (data?.[0] === 'group') {
          deleted.group_id = data[1]
        } else if (data?.[0] === 'mastery_paths') {
          deleted.noop_id = '1'
        }
        return deleted
      })
      onAssigneesChange?.(cardId, parsedCard, parsedDeletedCard)
    },
    [
      allOptions,
      defaultSectionId,
      disabledOptionIds,
      everyoneOption.id,
      hasModuleOverrides,
      onAssigneesChange,
    ]
  )

  const handleCardAssignment = useCallback(
    (cardId: string, assignees: AssigneeOption[], deletedAssignees: string[]) => {
      const selectedAssigneeIds = assignees.map(({id}) => id)
      const initialCard = initialCards.find(card => card.key === cardId)
      const areEquals =
        JSON.stringify(initialCard?.selectedAssigneeIds) === JSON.stringify(selectedAssigneeIds)
      const cards = assignToCards.map(card =>
        card.key === cardId
          ? {
              ...card,
              selectedAssigneeIds,
              highlightCard: !areEquals,
              isEdited: !areEquals,
              hasAssignees: assignees.length > 0,
            }
          : card
      )
      if (onAssigneesChange) {
        handleCustomAssigneesChange(cardId, assignees, deletedAssignees)
      }

      const allSelectedOptions = [...disabledOptionIds, ...assignees.map(({id}) => id)]
      const uniqueOptions = [...new Set(allSelectedOptions)]
      const newDisabled = uniqueOptions.filter(id =>
        deletedAssignees.length > 0 ? !deletedAssignees.includes(id) : true
      )

      setAssignToCards(cards)
      setDisabledOptionIds(newDisabled)
    },
    [
      assignToCards,
      disabledOptionIds,
      handleCustomAssigneesChange,
      initialCards,
      onAssigneesChange,
      setAssignToCards,
      setDisabledOptionIds,
    ]
  )

  const handleDatesChange = useCallback(
    (cardId: string, dateAttribute: string, dateValue: string | null) => {
      const newDate = dateValue // === null ? undefined : dateValue
      const initialCard = initialCards.find(card => card.key === cardId)
      const {highlightCard, isEdited, ...currentCardProps} = assignToCards.find(
        card => card.key === cardId
      ) as ItemAssignToCardSpec
      const currentCard = {...currentCardProps, [dateAttribute]: newDate}
      const priorCard = assignToCards.find(card => card.key === cardId)
      if (priorCard) {
        const dateChanged = priorCard[dateAttribute] !== dateValue
        if (!dateChanged) {
          // date did not change - do not setAssignToCards which would trigger a re-render)
          return
        }
      }
      const areEquals = JSON.stringify(initialCard) === JSON.stringify(currentCard)

      const newCard = {...currentCard, highlightCard: !areEquals, isEdited: !areEquals}
      const cards = assignToCards.map(card => (card.key === cardId ? newCard : card))
      setAssignToCards(cards)
      onDatesChange?.(cardId, dateAttribute, newDate ?? '')
    },
    [assignToCards, initialCards, onDatesChange, setAssignToCards]
  )

  const allCardsAssigned = useCallback(() => {
    return assignToCards.every(card => card.hasAssignees)
  }, [assignToCards])

  const stableCardRef = useCallback(
    (card, cardRef) => {
      if (cardRef) {
        cardsRefs.current[card.key] = cardRef
      }
    },
    [cardsRefs]
  )

  const renderCardsOptimized = useCallback(
    (isOpen?: boolean) => {
      const cardCount = assignToCards.length
      return assignToCards.map((card, i) => (
        // eslint-disable-next-line react/no-array-index-key
        <View key={`${card.key}-${i}`} as="div" margin="small 0 0 0">
          <ItemAssignToCardMemo
            ref={stableCardRef}
            courseId={courseId}
            contextModuleId={card.contextModuleId}
            contextModuleName={card.contextModuleName}
            removeDueDateInput={removeDueDateInput}
            isCheckpointed={isCheckpointed}
            cardId={card.key}
            reply_to_topic_due_at={card.reply_to_topic_due_at}
            required_replies_due_at={card.required_replies_due_at}
            due_at={card.due_at}
            original_due_at={card.original_due_at}
            unlock_at={card.unlock_at}
            lock_at={card.lock_at}
            onDelete={cardCount === 1 ? undefined : handleDeleteCard}
            onCardAssignmentChange={handleCardAssignment}
            onCardDatesChange={handleDatesChange}
            onValidityChange={handleCardValidityChange}
            isOpen={isOpen}
            disabledOptionIds={disabledOptionIds}
            everyoneOption={everyoneOption}
            selectedAssigneeIds={card.selectedAssigneeIds}
            customAllOptions={allOptions}
            customIsLoading={isLoadingAssignees}
            customSetSearchTerm={setSearchTerm}
            highlightCard={card.highlightCard}
            blueprintDateLocks={blueprintDateLocks}
            postToSIS={postToSIS}
          />
        </View>
      ))
    },
    [
      allOptions,
      assignToCards,
      blueprintDateLocks,
      courseId,
      disabledOptionIds,
      everyoneOption,
      handleCardAssignment,
      handleCardValidityChange,
      handleDatesChange,
      handleDeleteCard,
      isCheckpointed,
      isLoadingAssignees,
      postToSIS,
      removeDueDateInput,
      setSearchTerm,
      stableCardRef,
    ]
  )

  function renderCards(isOpen?: boolean) {
    const cardCount = assignToCards.length
    return assignToCards.map((card, i) => {
      return (
        // eslint-disable-next-line react/no-array-index-key
        <View key={`${card.key}-${i}`} as="div" margin="small 0 0 0">
          <ItemAssignToCard
            ref={cardRef => {
              if (cardRef) cardsRefs.current[card.key] = cardRef
            }}
            courseId={courseId}
            contextModuleId={card.contextModuleId}
            contextModuleName={card.contextModuleName}
            removeDueDateInput={removeDueDateInput}
            isCheckpointed={isCheckpointed}
            cardId={card.key}
            reply_to_topic_due_at={card.reply_to_topic_due_at}
            required_replies_due_at={card.required_replies_due_at}
            due_at={card.due_at}
            original_due_at={card.original_due_at}
            unlock_at={card.unlock_at}
            lock_at={card.lock_at}
            onDelete={cardCount === 1 ? undefined : handleDeleteCard}
            onCardAssignmentChange={handleCardAssignment}
            onCardDatesChange={handleDatesChange}
            onValidityChange={handleCardValidityChange}
            isOpen={isOpen}
            disabledOptionIds={disabledOptionIds}
            everyoneOption={everyoneOption}
            selectedAssigneeIds={card.selectedAssigneeIds}
            customAllOptions={allOptions}
            customIsLoading={isLoadingAssignees}
            customSetSearchTerm={setSearchTerm}
            highlightCard={card.highlightCard}
            blueprintDateLocks={blueprintDateLocks}
            postToSIS={postToSIS}
          />
        </View>
      )
    })
  }

  return (
    <Flex.Item padding="small medium" shouldGrow={true} shouldShrink={true}>
      {fetchInFlight || !loadedAssignees || isLoading ? (
        <Mask>
          <Spinner data-testid="cards-loading" renderTitle={I18n.t('Loading')} />
        </Mask>
      ) : (
        <ApplyLocale locale={locale} timezone={timezone}>
          {ENV.FEATURES?.selective_release_optimized_tray
            ? renderCardsOptimized(open)
            : renderCards(open)}
        </ApplyLocale>
      )}

      <Button
        onClick={handleAddCard}
        data-testid="add-card"
        margin="small 0 0 0"
        renderIcon={IconAddLine}
        interaction={!allCardsAssigned() || !!blueprintDateLocks?.length ? 'disabled' : 'enabled'}
        elementRef={el => (addCardButtonRef.current = el)}
      >
        {I18n.t('Add')}
      </Button>
    </Flex.Item>
  )
}

export default ItemAssignToTrayContent
