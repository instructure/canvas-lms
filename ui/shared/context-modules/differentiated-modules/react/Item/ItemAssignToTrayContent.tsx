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

import React, {
  useCallback,
  useEffect,
  memo,
  useRef,
  useState,
  type RefObject,
  type MutableRefObject,
  type RefAttributes,
  useMemo,
} from 'react'
import {Mask} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {Button} from '@instructure/ui-buttons'
import {ApplyLocale} from '@instructure/ui-i18n'
import {uid} from '@instructure/uid'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi, {type DoFetchApiOpts} from '@canvas/do-fetch-api-effect'
import type {
  AssigneeOption,
  BaseDateDetails,
  DateLockTypes,
  exportedOverride,
  FetchDueDatesResponse,
  ItemAssignToCardSpec,
} from './types'
import ItemAssignToCard, {
  type ItemAssignToCardProps,
  type ItemAssignToCardRef,
} from './ItemAssignToCard'
import {getOverriddenAssignees, itemTypeToApiURL} from '../../utils/assignToHelper'
import {getEveryoneOption, type ItemAssignToTrayProps} from './ItemAssignToTray'
import {getDueAtForCheckpointTag} from './utils'
import DifferentiationTagConverterMessage from '@canvas/differentiation-tags/react/DifferentiationTagConverterMessage/DifferentiationTagConverterMessage'

const I18n = createI18nScope('differentiated_modules')

export interface ItemAssignToTrayContentProps
  extends Omit<ItemAssignToTrayProps, 'iconType' | 'itemName'> {
  setAssignToCards: (cards: ItemAssignToCardSpec[]) => void
  blueprintDateLocks?: DateLockTypes[]
  setBlueprintDateLocks: (locks?: DateLockTypes[]) => void
  handleDismiss: () => void
  hasModuleOverrides: boolean
  setHasModuleOverrides: (state: boolean) => void
  hasDifferentiationTagOverrides: boolean
  setHasDifferentiationTagOverrides: (state: boolean) => void
  setModuleAssignees: (assignees: string[]) => void
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
  cardsRefs: MutableRefObject<{
    [cardId: string]: RefObject<ItemAssignToCardRef>
  }>
  postToSIS?: boolean
  assignToCardsRef: React.MutableRefObject<ItemAssignToCardSpec[]>
  disabledOptionIdsRef: React.MutableRefObject<string[]>
  isTray: boolean
  setOverrides?: (overrides: exportedOverride[] | null) => void
}

const MAX_PAGES = 10
const REPLY_TO_TOPIC = 'reply_to_topic'
const REPLY_TO_ENTRY = 'reply_to_entry'

function makeCardId(): string {
  return uid('assign-to-card', 12)
}

type OptimizedItemAssignToCardProps = ItemAssignToCardProps & RefAttributes<ItemAssignToCardRef>

const ItemAssignToCardMemo = memo(
  ItemAssignToCard,
  (prevProps: OptimizedItemAssignToCardProps, nextProps: OptimizedItemAssignToCardProps) => {
    // For improving performance, we should only validate Post to SIS if due_at is abscent
    const shouldValidatePostToSIS =
      prevProps.postToSIS !== nextProps.postToSIS &&
      (nextProps.due_at === null || nextProps.due_at === '')

    return !!(
      nextProps.persistEveryoneOption &&
      JSON.stringify(prevProps.customAllOptions) === JSON.stringify(nextProps.customAllOptions) &&
      prevProps.selectedAssigneeIds?.length === nextProps.selectedAssigneeIds?.length &&
      prevProps.initialAssigneeOptions?.length === nextProps.initialAssigneeOptions?.length &&
      prevProps.highlightCard === nextProps.highlightCard &&
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
      prevProps.contextModuleName === nextProps.contextModuleName &&
      !shouldValidatePostToSIS
    )
  },
)

const ItemAssignToTrayContent = ({
  open,
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
  hasDifferentiationTagOverrides,
  setHasDifferentiationTagOverrides,
  setModuleAssignees,
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
  assignToCardsRef,
  disabledOptionIdsRef,
  isTray,
  setOverrides = () => {},
}: ItemAssignToTrayContentProps) => {
  const [initialCards, setInitialCards] = useState<ItemAssignToCardSpec[]>([])
  const [fetchInFlight, setFetchInFlight] = useState(false)
  const [hasFetched, setHasFetched] = useState(false)
  const [refetchPages, setRefetchPages] = useState(false)

  const lastPerformedAction = useRef<{action: 'add' | 'delete'; index?: number} | null>(null)
  const addCardButtonRef = useRef<Element | null>(null)

  const isOpenRef = useRef<boolean>(false)

  useEffect(() => {
    isOpenRef.current = open
  }, [open])

  useEffect(() => {
    if (
      defaultCards === undefined ||
      !itemContentId ||
      itemType !== 'assignment' ||
      initialLoadRef.current
    )
      return

    const fetchAllPages = async () => {
      let url = itemTypeToApiURL(courseId, itemType, itemContentId)
      const allResponses = []
      setFetchInFlight(true)
      try {
        let pageCount = 0
        let args: DoFetchApiOpts = {
          path: url,
          params: {per_page: 100},
        }
        while (url && pageCount < MAX_PAGES) {
          // @ts-expect-error

          const response: FetchDueDatesResponse = await doFetchApi(args)
          allResponses.push(response.json)
          // @ts-expect-error
          url = response.link?.next?.url || null
          args = {
            path: url,
          }
          pageCount++
        }

        const combinedResponse = allResponses.reduce(
          (acc, response) => ({
            blueprint_date_locks: [
              // @ts-expect-error
              ...(acc.blueprint_date_locks || []),
              ...(response.blueprint_date_locks || []),
            ],
          }),
          {},
        )
        // @ts-expect-error
        setBlueprintDateLocks(combinedResponse.blueprint_date_locks)
      } catch {
        showFlashError()()
        handleDismiss()
      } finally {
        setHasFetched(true)
        setFetchInFlight(false)
        initialLoadRef.current = true
      }
    }
    !hasFetched && fetchAllPages()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    setGroupCategoryId(defaultGroupCategoryId)
  }, [defaultGroupCategoryId, setGroupCategoryId])

  useEffect(() => {
    if (assignToCardsRef.current.length === 0 && !lastPerformedAction.current) return
    const action = lastPerformedAction.current?.action
    const index = lastPerformedAction.current?.index || 0
    // If only a card remains, we should focus the add button
    const shouldFocusAddButton = action === 'delete' && assignToCardsRef.current.length <= 1
    let focusIndex
    if (shouldFocusAddButton && addCardButtonRef?.current instanceof HTMLButtonElement) {
      addCardButtonRef.current.disabled = false // so it can be focused
      addCardButtonRef.current.focus()
    } else if (action === 'add') {
      // Focus the last card
      focusIndex = assignToCardsRef.current.length - 1
    } else if (action === 'delete') {
      // Focus the previous card
      focusIndex = index <= 0 ? 0 : index - 1
    }
    if (focusIndex !== undefined) {
      const card = assignToCardsRef.current.at(focusIndex)
      if (card) {
        const cardRef = cardsRefs.current[card.key]
        if (cardRef?.current) {
          lastPerformedAction.current = null
          cardRef.current.focusDeleteButton()
        }
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [assignToCardsRef.current, cardsRefs])

  useEffect(() => {
    // Remove extra refs if cards array has shrunk
    Object.keys(cardsRefs.current).forEach(key => {
      if (!assignToCardsRef.current.some(card => card.key === key)) {
        delete cardsRefs.current[key]
      }
    })

    // Ensure cardsRefs has refs for all items
    assignToCardsRef.current.forEach(card => {
      if (!cardsRefs.current[card.key]) {
        cardsRefs.current[card.key] = React.createRef<ItemAssignToCardRef>()
      }
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [assignToCardsRef.current, cardsRefs])

  useEffect(() => {
    if (defaultCards !== undefined) {
      setAssignToCards(defaultCards)
    }
    setOverridesFetched(defaultCards !== undefined)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(defaultCards)])

  useEffect(() => {
    disabledOptionIdsRef.current = defaultDisabledOptionIds
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(defaultDisabledOptionIds)])

  useEffect(() => {
    if ((defaultCards !== undefined || itemContentId === undefined) && !refetchPages) {
      if (initHasModuleOverrides !== undefined && hasModuleOverrides !== undefined) {
        setHasModuleOverrides(initHasModuleOverrides)
      }

      if (assignToCardsRef.current.length > 0) {
        checkForDifferentiationTagOverrides()
      }
      return
    }

    const fetchAllPages = async () => {
      if (itemContentId === undefined) return
      setFetchInFlight(true)
      let url = itemTypeToApiURL(courseId, itemType, itemContentId)
      const allResponses = []

      try {
        let pageCount = 0
        let args: DoFetchApiOpts = {
          path: url,
          params: {
            per_page: 100,
            ...(itemType === 'discussion_topic' && {
              include: '',
            }),
          },
        }
        while (url && pageCount < MAX_PAGES) {
          // @ts-expect-error

          const response: FetchDueDatesResponse = await doFetchApi(args)
          allResponses.push(response.json)
          // @ts-expect-error
          url = response.link?.next?.url || null
          args = {
            path: url,
          }
          pageCount++
        }
        const combinedResponse = allResponses.reduce(
          (acc, response) => ({
            ...response,
            // @ts-expect-error
            overrides: [...(acc.overrides || []), ...(response.overrides || [])],
            blueprint_date_locks: [
              // @ts-expect-error
              ...(acc.blueprint_date_locks || []),
              ...(response.blueprint_date_locks || []),
            ],
          }),
          {},
        )

        const dateDetailsApiResponse = combinedResponse
        // @ts-expect-error
        const overrides = dateDetailsApiResponse.overrides
        const overriddenTargets = getOverriddenAssignees(overrides)
        // @ts-expect-error
        delete dateDetailsApiResponse.overrides
        // @ts-expect-error
        const baseDates: BaseDateDetails = dateDetailsApiResponse
        if (
          // @ts-expect-error
          dateDetailsApiResponse.checkpoints &&
          // @ts-expect-error
          Array.isArray(dateDetailsApiResponse.checkpoints)
        ) {
          // @ts-expect-error
          dateDetailsApiResponse.checkpoints.forEach((checkpoint: any) => {
            if (checkpoint.tag === REPLY_TO_ENTRY) {
              baseDates.required_replies_due_at = checkpoint.due_at
            } else if (checkpoint.tag === REPLY_TO_TOPIC) {
              baseDates.reply_to_topic_due_at = checkpoint.due_at
            }
          })
        }
        // @ts-expect-error
        const onlyOverrides = !dateDetailsApiResponse.visible_to_everyone
        const allModuleAssignees: string[] = []
        // @ts-expect-error
        const hasModuleOverride = overrides?.some(override => override.context_module_id)
        // @ts-expect-error
        const hasCourseOverride = overrides?.some(override => override.course_id)

        const cards: ItemAssignToCardSpec[] = []
        const selectedOptionIds: string[] = []
        if (!onlyOverrides && !hasCourseOverride) {
          // only add the regular everyone card if there isn't a course override
          const cardId = makeCardId()
          const selectedOption = [getEveryoneOption(assignToCardsRef.current.length > 1).id]
          cards.push({
            key: cardId,
            isValid: true,
            hasAssignees: true,
            due_at: baseDates.due_at,
            reply_to_topic_due_at: baseDates.reply_to_topic_due_at,
            required_replies_due_at: baseDates.required_replies_due_at,
            original_due_at: baseDates.due_at,
            unlock_at: baseDates.unlock_at,
            lock_at: baseDates.lock_at,
            selectedAssigneeIds: selectedOption,
            // @ts-expect-error
            overrideId: dateDetailsApiResponse.id,
          })
          selectedOptionIds.push(...selectedOption)
        }
        if (overrides?.length) {
          // @ts-expect-error
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
                // @ts-expect-error
                allModuleAssignees.push(...override.student_ids.map(id => `student-${id}`))
              }
              // Normal groups are not supported for module overrides
              // but differentiation tags are supported
              if (override.group_id && override.non_collaborative === true) {
                allModuleAssignees.push(`tag-${override.group_id}`)
              }
            }
            let removeCard = false
            let filteredStudents = override.students
            if (override.context_module_id && override.student_ids) {
              filteredStudents = filteredStudents?.filter(
                // @ts-expect-error
                student => !overriddenTargets?.students?.includes(student.id),
              )
              removeCard = override.student_ids?.length > 0 && filteredStudents?.length === 0
            }
            const studentOverrides =
              // @ts-expect-error
              filteredStudents?.map(student => ({
                id: `student-${student.id}`,
                value: student.name,
                group: 'Students',
              })) ?? []
            const initialAssigneeOptions = studentOverrides
            const defaultOptions = studentOverrides.map((option: {id: any}) => option.id)
            if (override.noop_id) {
              defaultOptions.push('mastery_paths')
            }
            if (override.course_section_id) {
              defaultOptions.push(`section-${override.course_section_id}`)
              initialAssigneeOptions.push({
                id: `section-${override.course_section_id}`,
                value: override.title,
                group: 'Sections',
              })
            }
            if (override.course_id) {
              defaultOptions.push('everyone')
            }
            if (override.group_id && !override.non_collaborative) {
              defaultOptions.push(`group-${override.group_id}`)
              initialAssigneeOptions.push({
                id: `group-${override.group_id}`,
                value: override.title,
                groupCategoryId: override.group_category_id,
                group: 'Groups',
              })
            }
            // Differentiation Tags
            if (override.group_id && override.non_collaborative) {
              setHasDifferentiationTagOverrides(true)

              defaultOptions.push(`tag-${override.group_id}`)
              initialAssigneeOptions.push({
                id: `tag-${override.group_id}`,
                value: override.title,
                groupCategoryId: override.group_category_id,
                group: 'Tags',
              })
            }
            removeCard = removeCard || override.student_ids?.length === 0
            if (removeCard || shouldRemoveCard(override, overriddenTargets)) {
              return
            }
            const cardId = makeCardId()
            const reply_to_topic_due_at = getDueAtForCheckpointTag(override, REPLY_TO_TOPIC)
            const required_replies_due_at = getDueAtForCheckpointTag(override, REPLY_TO_ENTRY)

            cards.push({
              key: cardId,
              isValid: true,
              hasAssignees: true,
              due_at: override.due_at,
              reply_to_topic_due_at,
              required_replies_due_at,
              original_due_at: override.due_at,
              unlock_at: override.unlock_at,
              lock_at: override.lock_at,
              selectedAssigneeIds: defaultOptions,
              defaultOptions,
              initialAssigneeOptions,
              overrideId: override.id,
              contextModuleId: override.context_module_id,
              contextModuleName: override.context_module_name,
            })
            selectedOptionIds.push(...defaultOptions)
          })
        }
        setModuleAssignees(allModuleAssignees)
        setHasModuleOverrides(hasModuleOverride || false)
        // @ts-expect-error
        setGroupCategoryId(dateDetailsApiResponse.group_category_id)
        setOverridesFetched(true)
        // @ts-expect-error
        setBlueprintDateLocks(dateDetailsApiResponse.blueprint_date_locks)
        disabledOptionIdsRef.current = selectedOptionIds
        setInitialCards(cards)
        onInitialStateSet?.(cards)
        setAssignToCards(cards)
        if (refetchPages) {
          setOverrides(overrides)
        }
      } catch {
        showFlashError()()
        handleDismiss()
      } finally {
        setHasFetched(true)
        setFetchInFlight(false)
        initialLoadRef.current = true
        setRefetchPages(false)
      }
    }
    if (!hasFetched || refetchPages) {
      fetchAllPages()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseId, itemContentId, itemType, JSON.stringify(defaultCards), refetchPages])

  const handleAddCard = () => {
    lastPerformedAction.current = {action: 'add'}
    if (onAddCard) {
      onAddCard()
      return
    }
    const cardId = makeCardId()
    const cards: ItemAssignToCardSpec[] = [
      ...assignToCardsRef.current,
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
    setAssignToCards(cards)
  }

  const checkForDifferentiationTagOverrides = () => {
    const hasDifferentiationTagOverrides = assignToCardsRef.current.some(card => {
      const selectedAssigneeIds = card.selectedAssigneeIds
      return selectedAssigneeIds.length > 0 && selectedAssigneeIds.some(id => id.includes('tag-'))
    })

    if (hasDifferentiationTagOverrides) {
      setHasDifferentiationTagOverrides(true)
    } else {
      setHasDifferentiationTagOverrides(false)
    }
  }

  const handleDeleteCard = useCallback(
    (cardId: string) => {
      const cardIndex = assignToCardsRef.current.findIndex(card => card.key === cardId)
      const cardSelection = assignToCardsRef.current.at(cardIndex)?.selectedAssigneeIds ?? []
      const newDisabled = disabledOptionIdsRef.current.filter(id => !cardSelection.includes(id))
      const cards = assignToCardsRef.current.filter(({key}) => key !== cardId)
      lastPerformedAction.current = {action: 'delete', index: cardIndex}
      setAssignToCards(cards)
      disabledOptionIdsRef.current = newDisabled
      onCardRemove?.(cardId)

      if (!ENV.ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS && hasDifferentiationTagOverrides === true) {
        checkForDifferentiationTagOverrides()
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [onCardRemove, setAssignToCards],
  )

  const shouldRemoveCard = (override: ItemAssignToCardSpec, overriddenTargets: any) => {
    if (!overriddenTargets) {
      return false
    }
    const alreadyHasItemSectionOverride =
      override.context_module_id &&
      override?.course_section_id &&
      overriddenTargets?.sections?.includes(override.course_section_id)
    const alreadyHasItemDifferentiationTagOverride =
      override.context_module_id &&
      override?.group_id &&
      overriddenTargets?.differentiationTags?.includes(override.group_id)
    return alreadyHasItemSectionOverride || alreadyHasItemDifferentiationTagOverride
  }

  const handleCardValidityChange = useCallback(
    (cardId: string, isValid: boolean) => {
      const priorCard = assignToCardsRef.current.find(card => card.key === cardId)
      if (priorCard) {
        const validityChanged = priorCard.isValid !== isValid
        if (!validityChanged) {
          return
        }
      }
      const cards = assignToCardsRef.current.map(card =>
        card.key === cardId ? {...card, isValid} : card,
      )
      setAssignToCards(cards)
    },
    [assignToCardsRef, setAssignToCards],
  )

  const handleCustomAssigneesChange = useCallback(
    (cardId: string, assignees: AssigneeOption[], deletedAssignees: string[]) => {
      const newSelectedOption = assignees.filter(
        assignee => !disabledOptionIdsRef.current.includes(assignee.id),
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
      } else if (
        (parsedCard.id && idData[0] === 'group') ||
        (parsedCard.id && idData[0] === 'tag')
      ) {
        parsedCard.group_id = idData[1]
        parsedCard.group_category_id = newSelectedOption.groupCategoryId
        parsedCard.non_collaborative = idData[0] === 'tag' ? true : false
      } else if (idData && idData[0] === 'mastery_paths') {
        parsedCard.noop_id = '1'
      }

      const parsedDeletedCard = deletedAssignees.map(id => {
        const card = allOptions.find(a => a.id === id)
        const data = !card && isLoadingAssignees ? id?.split('-') : card?.id?.split('-')
        const deleted = {name: card?.value, type: data?.[0]} as exportedOverride

        if (id === everyoneOption.id) {
          deleted.course_section_id = defaultSectionId
        } else if (data?.[0] === 'section') {
          deleted.course_section_id = data[1]
        } else if (data?.[0] === 'student') {
          deleted.short_name = card?.value
          deleted.student_id = data[1]
        } else if (data?.[0] === 'group' || data?.[0] === 'tag') {
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
      disabledOptionIdsRef,
      everyoneOption.id,
      hasModuleOverrides,
      isLoadingAssignees,
      onAssigneesChange,
    ],
  )

  const handleCardAssignment = useCallback(
    (cardId: string, assignees: AssigneeOption[], deletedAssignees: string[]) => {
      const selectedAssigneeIds = assignees.map(({id}) => id)
      const initialCard = initialCards.find(card => card.key === cardId)
      const areEquals =
        JSON.stringify(initialCard?.selectedAssigneeIds) === JSON.stringify(selectedAssigneeIds)

      const studentAssignees = selectedAssigneeIds.filter(assignee => assignee.includes('student'))
      const sectionAssignees = selectedAssigneeIds.filter(assignee => assignee.includes('section'))
      const differentiationTagAssignees = selectedAssigneeIds.filter(assignee =>
        assignee.includes('tag'),
      )

      // this is useful in the page edit page for checking if a module override has been changed
      const hasInitialAssignees =
        sectionAssignees?.includes(initialCard?.defaultOptions?.[0] ?? '') ||
        differentiationTagAssignees?.includes(initialCard?.defaultOptions?.[0] ?? '') ||
        JSON.stringify(studentAssignees) === JSON.stringify(initialCard?.defaultOptions)

      const cards = assignToCardsRef.current.map(card =>
        card.key === cardId
          ? {
              ...card,
              selectedAssigneeIds,
              highlightCard: !areEquals,
              isEdited: !areEquals,
              hasAssignees: assignees.length > 0,
              hasInitialOverride: hasInitialAssignees,
            }
          : card,
      )
      if (onAssigneesChange) {
        handleCustomAssigneesChange(cardId, assignees, deletedAssignees)
      } else {
        const allSelectedOptions = [...disabledOptionIdsRef.current, ...assignees.map(({id}) => id)]
        const uniqueOptions = [...new Set(allSelectedOptions)]
        const newDisabled = uniqueOptions.filter(id =>
          deletedAssignees.length > 0 ? !deletedAssignees.includes(id) : true,
        )
        disabledOptionIdsRef.current = newDisabled
      }

      setAssignToCards(cards)
    },
    [
      assignToCardsRef,
      disabledOptionIdsRef,
      handleCustomAssigneesChange,
      initialCards,
      onAssigneesChange,
      setAssignToCards,
    ],
  )

  const handleDatesChange = useCallback(
    (cardId: string, dateAttribute: string, dateValue: string | null) => {
      const newDate = dateValue // === null ? undefined : dateValue
      const initialCard = initialCards.find(card => card.key === cardId)
      const currentCardProps = assignToCardsRef.current.find(
        card => card.key === cardId,
      ) as ItemAssignToCardSpec
      const currentCard = {...currentCardProps, [dateAttribute]: newDate}
      const priorCard = assignToCardsRef.current.find(card => card.key === cardId)
      if (priorCard) {
        const dateChanged = priorCard[dateAttribute] !== dateValue
        if (!dateChanged) {
          // date did not change - do not setAssignToCards which would trigger a re-render)
          return
        }
      }
      const areEquals = JSON.stringify(initialCard) === JSON.stringify(currentCard)

      const newCard = {...currentCard, highlightCard: !areEquals, isEdited: !areEquals}
      const cards = assignToCardsRef.current.map(card => (card.key === cardId ? newCard : card))
      setAssignToCards(cards)
      onDatesChange?.(cardId, dateAttribute, newDate ?? '')
    },
    [assignToCardsRef, initialCards, onDatesChange, setAssignToCards],
  )

  const allCardsAssigned = () => {
    return assignToCardsRef.current.every(card => card.hasAssignees)
  }

  const addCardButton = (firstButton: boolean) => {
    return (
      <Button
        display={isTray ? undefined : 'block'}
        onClick={handleAddCard}
        data-testid="add-card"
        margin="small 0 0 0"
        // @ts-expect-error
        renderIcon={IconAddLine}
        interaction={!allCardsAssigned() || !!blueprintDateLocks?.length ? 'disabled' : 'enabled'}
        elementRef={firstButton ? undefined : el => (addCardButtonRef.current = el)}
      >
        {isTray ? I18n.t('Add') : I18n.t('Assign To')}
      </Button>
    )
  }

  const renderCards = useCallback(
    () => {
      const cardCount = assignToCardsRef.current.length
      return assignToCardsRef.current.map(card => (
        <View key={`${card.key}`} as="div" margin="small 0 0 0">
          <ItemAssignToCardMemo
            // Make sure the cards get rendered when there is only one card or when jumping to two cards
            // since the everyone option needs to be updated.
            // Having cardCount > 2 will prevent the cards to be rendered when having more cards
            // since in that snacerio the everyone option won't change.
            persistEveryoneOption={cardCount !== 1 && cardCount > 2}
            ref={cardsRefs.current[card.key]}
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
            isOpenRef={isOpenRef}
            // @ts-expect-error
            disabledOptionIds={disabledOptionIdsRef.current}
            everyoneOption={everyoneOption}
            selectedAssigneeIds={card.selectedAssigneeIds}
            initialAssigneeOptions={card.initialAssigneeOptions}
            customAllOptions={allOptions}
            customIsLoading={isLoadingAssignees}
            customSetSearchTerm={setSearchTerm}
            highlightCard={card.highlightCard}
            blueprintDateLocks={blueprintDateLocks}
            postToSIS={postToSIS}
            disabledOptionIdsRef={disabledOptionIdsRef}
            loadedAssignees={loadedAssignees}
            itemType={itemType}
          />
        </View>
      ))
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [
      assignToCardsRef,
      cardsRefs,
      courseId,
      removeDueDateInput,
      isCheckpointed,
      handleDeleteCard,
      handleCardAssignment,
      handleDatesChange,
      handleCardValidityChange,
      everyoneOption,
      allOptions,
      isLoadingAssignees,
      setSearchTerm,
      blueprintDateLocks,
      postToSIS,
      disabledOptionIdsRef,
      defaultGroupCategoryId,
    ],
  )

  const shouldShowAddCard = useMemo(() => {
    if (!(itemType === 'discussion' || itemType === 'discussion_topic')) return true
    return !ENV?.current_user_is_student
  }, [itemType])

  return (
    <Flex.Item padding="small medium" shouldGrow={true} shouldShrink={true}>
      {!ENV.ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS && hasDifferentiationTagOverrides && (
        <DifferentiationTagConverterMessage
          courseId={courseId}
          learningObjectId={String(itemContentId)}
          learningObjectType={itemType}
          onFinish={() => {
            setRefetchPages(true)
            setHasFetched(false)
            setHasDifferentiationTagOverrides(false)
          }}
        />
      )}
      {shouldShowAddCard && assignToCardsRef.current.length > 3 && addCardButton(true)}
      {fetchInFlight || !loadedAssignees || isLoading ? (
        isTray ? (
          <Mask>
            <Spinner data-testid="cards-loading" renderTitle={I18n.t('Loading')} />
          </Mask>
        ) : (
          <Spinner data-testid="cards-loading" renderTitle={I18n.t('Loading')} />
        )
      ) : (
        <ApplyLocale locale={locale} timezone={timezone}>
          {renderCards()}
        </ApplyLocale>
      )}
      {shouldShowAddCard && addCardButton(false)}
    </Flex.Item>
  )
}

export default ItemAssignToTrayContent
