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

import React, {
  createRef,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type RefObject,
} from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {
  IconAssignmentLine,
  IconQuizLine,
  IconQuizSolid,
  IconQuestionLine,
  IconDiscussionLine,
  IconDocumentLine,
} from '@instructure/ui-icons'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {lockLabels} from '@canvas/blueprint-courses/react/labels'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {DateDetails, DateLockTypes, exportedOverride, ItemAssignToCardSpec} from './types'
import {
  type ItemAssignToCardCustomValidationArgs,
  type ItemAssignToCardRef,
} from './ItemAssignToCard'
import TrayFooter from '../Footer'
import {generateDateDetailsPayload, itemTypeToApiURL} from '../../utils/assignToHelper'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import type {IconType, ItemType} from '../types'
import ItemAssignToTrayContent from './ItemAssignToTrayContent'
import CoursePacingNotice from '@canvas/due-dates/react/CoursePacingNotice'
import useFetchAssignees from '../../utils/hooks/useFetchAssignees'
import {calculateMasqueradeHeight} from '../../utils/miscHelpers'
import MasteryPathToggle from '@canvas/mastery-path-toggle/react/MasteryPathToggle'
import {FormField} from '@instructure/ui-form-field'
import {
  CONVERT_DIFF_TAGS_MESSAGE,
  CONVERT_DIFF_TAGS_BUTTON,
} from '@canvas/differentiation-tags/react/DifferentiationTagConverterMessage/DifferentiationTagConverterMessage'

const I18n = createI18nScope('differentiated_modules')

function itemTypeToIcon(iconType: IconType) {
  switch (iconType) {
    case 'assignment':
      return <IconAssignmentLine data-testid="icon-assignment" />
    case 'quiz':
      return <IconQuizLine data-testid="icon-quiz" />
    case 'lti-quiz':
      return <IconQuizSolid data-testid="icon-lti-quiz" />
    case 'discussion':
    case 'discussion_topic':
      return <IconDiscussionLine data-testid="icon-discussion" />
    case 'page':
    case 'wiki_page':
      return <IconDocumentLine data-testid="icon-page" />
    default:
      return <IconQuestionLine data-testid="icon-unknown" />
  }
}

export function getEveryoneOption(hasOverrides: boolean) {
  return {
    id: 'everyone',
    value: hasOverrides ? I18n.t('Everyone else') : I18n.t('Everyone'),
  }
}

export const updateModuleItem = ({
  courseId,
  moduleItemType,
  moduleItemName,
  moduleItemContentId,
  payload,
  onSuccess,
  onLoading,
}: {
  courseId: string
  moduleItemType: ItemType
  moduleItemName: string
  moduleItemContentId: string
  payload: DateDetails
  onLoading: (flag: boolean) => void
  onSuccess: () => void
}) => {
  onLoading(true)
  return doFetchApi({
    path: itemTypeToApiURL(courseId, moduleItemType, moduleItemContentId),
    method: 'PUT',
    body: payload,
  })
    .then(() => {
      showFlashAlert({
        type: 'success',
        message: I18n.t(`%{moduleItemName} updated`, {moduleItemName}),
      })
      onSuccess()
      window.location.reload()
    })
    .catch((err: Error) => {
      showFlashAlert({
        err,
        message: I18n.t(`Error updating "%{moduleItemName}`, {moduleItemName}),
      })
    })
    .finally(() => onLoading(false))
}

// TODO: need props to initialize with cards corresponding to current assignments
export interface ItemAssignToTrayProps {
  open: boolean
  onSave?: (
    overrides: ItemAssignToCardSpec[],
    hasModuleOverrides: boolean,
    deletedModuleAssignees: string[],
    disabledOptionIds?: string[],
  ) => void
  onChange?: (
    overrides: ItemAssignToCardSpec[],
    hasModuleOverrides: boolean,
    deletedModuleAssignees: string[],
    disabledOptionIds?: string[],
    moduleOverrides?: ItemAssignToCardSpec[],
  ) => ItemAssignToCardSpec[]
  onClose: () => void
  onDismiss: () => void
  onExited?: () => void
  courseId: string
  itemName: string
  itemType: ItemType
  iconType: IconType
  itemContentId?: string
  initHasModuleOverrides?: boolean
  defaultGroupCategoryId?: string | null
  pointsPossible?: number | null
  locale: string
  timezone: string
  defaultCards?: ItemAssignToCardSpec[]
  defaultDisabledOptionIds?: string[]
  defaultSectionId?: string
  useApplyButton?: boolean
  removeDueDateInput?: boolean
  isCheckpointed?: boolean
  onAddCard?: () => void
  onAssigneesChange?: (
    cardId: string,
    newAssignee: Record<string, any>,
    deletedAssignee: Record<string, any>[],
  ) => void
  onDatesChange?: (cardId: string, dateType: string, newDate: string) => void
  onCardRemove?: (cardId: string) => void
  onInitialStateSet?: (cards: ItemAssignToCardSpec[]) => void
  postToSIS?: boolean
  isTray?: boolean
  setOverrides?: (overrides: exportedOverride[] | null) => void
}

export default function ItemAssignToTray({
  open,
  onSave,
  onChange,
  onClose,
  onExited,
  onDismiss,
  courseId,
  itemName,
  itemType,
  iconType,
  itemContentId,
  defaultGroupCategoryId = null,
  pointsPossible,
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
  useApplyButton = false,
  removeDueDateInput = false,
  isCheckpointed = false,
  onInitialStateSet,
  postToSIS = false,
  isTray = true,
  setOverrides,
}: ItemAssignToTrayProps) {
  const isPacedCourse = ENV.IN_PACED_COURSE
  const isMasteryPathCourse =
    !!ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && ENV.FEATURES.course_pace_pacing_with_mastery_paths
  const initialLoadRef = useRef(false)
  const cardsRefs = useRef<{[cardId: string]: RefObject<ItemAssignToCardRef>}>({})
  const [isLoading, setIsLoading] = useState(false)
  const [initialCardsState, setInitialCardsState] = useState<ItemAssignToCardSpec[]>([])

  const [assignToCards, setAssignToCardsInner] = useState<ItemAssignToCardSpec[]>(
    defaultCards ?? [],
  )
  const setAssignToCards = (cards: ItemAssignToCardSpec[]) => {
    assignToCardsRef.current = cards
    setAssignToCardsInner(cards)
  }

  const [hasModuleOverrides, setHasModuleOverrides] = useState(false)
  const [hasDifferentiationTagOverrides, setHasDifferentiationTagOverrides] = useState(false)
  const [moduleAssignees, setModuleAssignees] = useState<string[]>([])
  const [groupCategoryId, setGroupCategoryId] = useState<string | null>(defaultGroupCategoryId)
  const [overridesFetched, setOverridesFetched] = useState(
    defaultCards !== undefined && defaultCards.length > 0,
  )
  const [blueprintDateLocks, setBlueprintDateLocks] = useState<DateLockTypes[] | undefined>(
    // On the edit pages, the ENV will contain this data, so we can initialize the lock info here. We'll fall back to
    // fetching it via the date details API in other cases.
    ENV.MASTER_COURSE_DATA?.is_master_course_child_content &&
      ENV.MASTER_COURSE_DATA?.restricted_by_master_course
      ? (Object.entries(ENV.MASTER_COURSE_DATA?.master_course_restrictions ?? {})
          .filter(([_lockType, locked]) => locked)
          .filter(([lockType]) => ['due_dates', 'availability_dates'].includes(lockType))
          .map(([lockType]) => lockType) as DateLockTypes[])
      : undefined,
  )
  const assignToCardsRef = useRef(assignToCards)
  const disabledOptionIdsRef = useRef(defaultDisabledOptionIds)
  const sectionViewRef = createRef<View>()

  const handleInitialState = (state: ItemAssignToCardSpec[]) => {
    onInitialStateSet?.(state)
    setInitialCardsState(state)
  }

  const mustConvertTags = useCallback(() => {
    return !ENV.ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS && hasDifferentiationTagOverrides
  }, [hasDifferentiationTagOverrides])

  useEffect(() => {
    // When tray closes and the initial load already happened,
    // the next time it opens it will show the loading spinner
    // because the cards rendering is a heavy process, letting
    // the user knows the tray is loading instead of being frozen
    if (!open && initialLoadRef.current) {
      setIsLoading(true)
    }
  }, [open])

  useEffect(() => {
    if (defaultCards && initialCardsState.length < 1) {
      setInitialCardsState(defaultCards)
    }
  }, [defaultCards, initialCardsState.length])

  useEffect(() => {
    if (onChange === undefined) return
    const deletedModuleAssignees = moduleAssignees.filter(
      override => !disabledOptionIdsRef.current.includes(override),
    )
    const moduleOverrides = hasModuleOverrides ? defaultCards?.filter(o => o.contextModuleId) : []
    const newCards = onChange(
      assignToCardsRef.current,
      hasModuleOverrides,
      deletedModuleAssignees,
      disabledOptionIdsRef.current,
      moduleOverrides,
    )
    setAssignToCards(newCards)
  }, [assignToCards, defaultCards, hasModuleOverrides, moduleAssignees, onChange])

  const hasChanges =
    assignToCards.some(({highlightCard}) => highlightCard) ||
    assignToCards.length < initialCardsState.length

  const everyoneOption = useMemo(() => {
    const hasOverrides =
      (disabledOptionIdsRef.current.length === 1 &&
        !disabledOptionIdsRef.current.includes('everyone')) ||
      disabledOptionIdsRef.current.length > 1 ||
      assignToCardsRef.current.length > 1
    return getEveryoneOption(hasOverrides)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [disabledOptionIdsRef, assignToCardsRef.current])

  const handleDismiss = useCallback(() => {
    if (defaultCards) {
      setAssignToCards(defaultCards)
    }
    onDismiss?.()
  }, [defaultCards, onDismiss])

  const masteryPathsAllowed = !(
    ['discussion', 'discussion_topic'].includes(itemType) && removeDueDateInput
  )

  const {
    allOptions,
    isLoading: isLoadingAssignees,
    loadedAssignees,
    setSearchTerm,
  } = useFetchAssignees({
    courseId,
    groupCategoryId,
    disableFetch: !overridesFetched || isPacedCourse,
    everyoneOption,
    checkMasteryPaths: masteryPathsAllowed,
    defaultValues: [],
    onError: handleDismiss,
  })

  const focusErrors = useCallback(() => {
    if (mustConvertTags()) {
      const button = document.getElementById(CONVERT_DIFF_TAGS_BUTTON)
      button?.setAttribute('aria-describedby', CONVERT_DIFF_TAGS_MESSAGE)
      button?.focus()
      return true
    }

    const hasErrors = assignToCards.some(card => !card.isValid)
    // If a card has errors it should not save and the respective card should be focused
    if (hasErrors) {
      const firstCardWithError = assignToCards.find(card => !card.isValid)
      if (!firstCardWithError) return false
      const firstCardWithErrorRef = cardsRefs.current[firstCardWithError.key]

      Object.values(cardsRefs.current).forEach(c => c.current?.showValidations())
      firstCardWithErrorRef?.current?.focusInputs()
      return true
    }
    return false
  }, [assignToCards])

  const handleUpdate = useCallback(() => {
    if (focusErrors()) return
    if (!hasChanges) {
      onDismiss()
      return
    }
    // compare original module assignees to see if they were removed for unassign_item overrides
    const deletedModuleAssignees = moduleAssignees.filter(
      override => !disabledOptionIdsRef.current.includes(override),
    )

    if (onSave !== undefined) {
      onSave(
        assignToCardsRef.current,
        hasModuleOverrides,
        deletedModuleAssignees,
        disabledOptionIdsRef.current,
      )
      return
    }
    const filteredCards = assignToCardsRef.current.filter(
      card =>
        [null, undefined, ''].includes(card.contextModuleId) ||
        (card.contextModuleId !== null && card.isEdited),
    )
    const payload = generateDateDetailsPayload(
      filteredCards,
      hasModuleOverrides,
      deletedModuleAssignees,
    )
    if (itemContentId !== undefined) {
      updateModuleItem({
        courseId,
        moduleItemContentId: itemContentId,
        moduleItemType: itemType,
        moduleItemName: itemName,
        payload,
        onLoading: setIsLoading,
        onSuccess: handleDismiss,
      })
    }
  }, [
    focusErrors,
    hasChanges,
    moduleAssignees,
    onDismiss,
    onSave,
    hasModuleOverrides,
    itemContentId,
    courseId,
    itemType,
    itemName,
    handleDismiss,
  ])

  const allCardsValid = useCallback(() => {
    if (mustConvertTags()) {
      return false
    } else {
      return assignToCardsRef.current.every(card => card.isValid)
    }
  }, [assignToCardsRef, hasDifferentiationTagOverrides])

  const handleEntered = useCallback(() => {
    // When tray entered and the initial load already happened,
    // this will start the cards render process
    if (open && initialLoadRef.current) {
      setIsLoading(false)
    }
  }, [open])

  useEffect(() => {
    if (!isTray && sectionViewRef.current?.ref) {
      // @ts-expect-error: Property 'reactComponentInstance' does not exist on type 'Element'
      sectionViewRef.current.ref.reactComponentInstance = {
        focusErrors,
        allCardsValid,
        mustConvertTags,
        // Runs custom card validations with current data and returns true if all cards are valid
        allCardsValidCustom: (params: ItemAssignToCardCustomValidationArgs) =>
          !Object.values(cardsRefs.current).some(
            c => c.current && Object.keys(c.current.runCustomValidations(params)).length !== 0,
          ),
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isTray, focusErrors])

  const renderPointsPossible = () =>
    pointsPossible === 1 ? I18n.t('1 pt') : I18n.t('%{pointsPossible} pts', {pointsPossible})

  function Header() {
    const icon = itemTypeToIcon(iconType)
    return (
      <Flex.Item margin="x-large 0 small" padding="0 medium" width="100%">
        <CloseButton
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
        />
        <Heading level="h2">
          {icon} {itemName}
        </Heading>
        <View data-testid="item-type-text" as="div" margin="medium 0 0 0">
          {renderItemType()} {pointsPossible != null && `| ${renderPointsPossible()}`}
        </View>
        {(blueprintDateLocks?.length ?? 0) < 2 ? (
          <Alert liveRegion={getLiveRegion} variant="info" margin="small 0 0">
            <Text size="small">
              {I18n.t(
                'Select who should be assigned and use the drop-down menus or manually enter your date and time.',
              )}
            </Text>
          </Alert>
        ) : null}
        {blueprintDateLocks && blueprintDateLocks.length > 0 ? (
          <Alert liveRegion={getLiveRegion} variant="info" margin="small 0 0">
            <Text weight="bold" size="small">
              {I18n.t('Locked: ')}
            </Text>
            <Text size="small">{blueprintDateLocks.map(i => lockLabels[i]).join(' & ')}</Text>
          </Alert>
        ) : null}
      </Flex.Item>
    )
  }

  function renderItemType() {
    switch (iconType) {
      case 'assignment':
        return I18n.t('Assignment')
      case 'quiz':
        return I18n.t('Quiz')
      case 'lti-quiz':
        return I18n.t('Quiz')
      case 'discussion':
      case 'discussion_topic':
        return I18n.t('Discussion')
      case 'page':
      case 'wiki_page':
        return I18n.t('Page')
      default:
        return ''
    }
  }

  function Footer() {
    const masqueradeBar = calculateMasqueradeHeight()
    const padding = masqueradeBar > 0 ? '0 0 x-large 0' : 'none'
    return (
      <Flex.Item data-testid="module-item-edit-tray-footer" width="100%" padding={padding}>
        <TrayFooter
          disableSave={isPacedCourse && !isMasteryPathCourse}
          saveButtonLabel={useApplyButton ? I18n.t('Apply') : I18n.t('Save')}
          onDismiss={handleDismiss}
          onUpdate={handleUpdate}
          hasErrors={!allCardsValid()}
        />
      </Flex.Item>
    )
  }

  const trayView = (
    <View id="manage-assign-to-container" width="100%" display="block" ref={sectionViewRef}>
      <Tray
        data-testid="module-item-edit-tray"
        onClose={onClose}
        onExited={onExited}
        onEntered={handleEntered}
        label={I18n.t('Edit assignment %{name}', {
          name: itemName,
        })}
        open={open}
        placement="end"
        size="regular"
      >
        <Flex direction="column" height="100vh" width="100%">
          {Header()}
          {isPacedCourse ? (
            <Flex.Item padding="large medium small medium" shouldGrow={true} shouldShrink={true}>
              <CoursePacingNotice courseId={courseId} />
              {isMasteryPathCourse && (
                <FormField id="mastery-path-toggle" label={I18n.t('Mastery Paths')}>
                  <MasteryPathToggle
                    overrides={assignToCards}
                    onSync={setAssignToCards}
                    courseId={courseId}
                    itemType={itemType}
                    itemContentId={itemContentId}
                    useCards
                    fetchOwnOverrides={false}
                  />
                </FormField>
              )}
            </Flex.Item>
          ) : (
            <ItemAssignToTrayContent
              open={open}
              initialLoadRef={initialLoadRef}
              onClose={onClose}
              onDismiss={onDismiss}
              courseId={courseId}
              itemType={itemType}
              itemContentId={itemContentId}
              locale={locale}
              timezone={timezone}
              initHasModuleOverrides={initHasModuleOverrides}
              removeDueDateInput={removeDueDateInput}
              isCheckpointed={isCheckpointed}
              onInitialStateSet={handleInitialState}
              defaultCards={defaultCards}
              defaultSectionId={defaultSectionId}
              defaultDisabledOptionIds={defaultDisabledOptionIds}
              onSave={onSave}
              onAddCard={onAddCard}
              onAssigneesChange={onAssigneesChange}
              onDatesChange={onDatesChange}
              onCardRemove={onCardRemove}
              setAssignToCards={setAssignToCards}
              blueprintDateLocks={blueprintDateLocks}
              setBlueprintDateLocks={setBlueprintDateLocks}
              handleDismiss={handleDismiss}
              hasModuleOverrides={hasModuleOverrides}
              setHasModuleOverrides={setHasModuleOverrides}
              hasDifferentiationTagOverrides={hasDifferentiationTagOverrides}
              setHasDifferentiationTagOverrides={setHasDifferentiationTagOverrides}
              cardsRefs={cardsRefs}
              setModuleAssignees={setModuleAssignees}
              defaultGroupCategoryId={defaultGroupCategoryId}
              allOptions={allOptions}
              isLoadingAssignees={isLoadingAssignees}
              isLoading={isLoading}
              loadedAssignees={loadedAssignees}
              setSearchTerm={setSearchTerm}
              everyoneOption={everyoneOption}
              setGroupCategoryId={setGroupCategoryId}
              setOverridesFetched={setOverridesFetched}
              postToSIS={postToSIS}
              assignToCardsRef={assignToCardsRef}
              disabledOptionIdsRef={disabledOptionIdsRef}
              isTray={isTray}
            />
          )}
          {Footer()}
        </Flex>
      </Tray>
    </View>
  )

  const sectionView = (
    <View id="manage-assign-to-container" width="100%" display="block" ref={sectionViewRef}>
      {blueprintDateLocks && blueprintDateLocks.length > 0 ? (
        <Alert liveRegion={getLiveRegion} variant="info" margin="small 0 0">
          <Text weight="bold" size="small">
            {I18n.t('Locked: ')}
          </Text>
          <Text size="small">{blueprintDateLocks.map(i => lockLabels[i]).join(' & ')}</Text>
        </Alert>
      ) : null}
      {isPacedCourse ? (
        <Flex.Item padding="small medium" shouldGrow={true} shouldShrink={true}>
          <CoursePacingNotice courseId={courseId} />
        </Flex.Item>
      ) : (
        <ItemAssignToTrayContent
          open={open}
          initialLoadRef={initialLoadRef}
          onClose={onClose}
          onDismiss={onDismiss}
          courseId={courseId}
          itemType={itemType}
          itemContentId={itemContentId}
          locale={locale}
          timezone={timezone}
          initHasModuleOverrides={initHasModuleOverrides}
          removeDueDateInput={removeDueDateInput}
          isCheckpointed={isCheckpointed}
          onInitialStateSet={handleInitialState}
          defaultCards={defaultCards}
          defaultSectionId={defaultSectionId}
          defaultDisabledOptionIds={defaultDisabledOptionIds}
          onSave={onSave}
          onAddCard={onAddCard}
          onAssigneesChange={onAssigneesChange}
          onDatesChange={onDatesChange}
          onCardRemove={onCardRemove}
          setAssignToCards={setAssignToCards}
          blueprintDateLocks={blueprintDateLocks}
          setBlueprintDateLocks={setBlueprintDateLocks}
          handleDismiss={handleDismiss}
          hasModuleOverrides={hasModuleOverrides}
          setHasModuleOverrides={setHasModuleOverrides}
          hasDifferentiationTagOverrides={hasDifferentiationTagOverrides}
          setHasDifferentiationTagOverrides={setHasDifferentiationTagOverrides}
          cardsRefs={cardsRefs}
          setModuleAssignees={setModuleAssignees}
          defaultGroupCategoryId={defaultGroupCategoryId}
          allOptions={allOptions}
          isLoadingAssignees={isLoadingAssignees}
          isLoading={isLoading}
          loadedAssignees={loadedAssignees}
          setSearchTerm={setSearchTerm}
          everyoneOption={everyoneOption}
          setGroupCategoryId={setGroupCategoryId}
          setOverridesFetched={setOverridesFetched}
          postToSIS={postToSIS}
          assignToCardsRef={assignToCardsRef}
          disabledOptionIdsRef={disabledOptionIdsRef}
          isTray={isTray}
          setOverrides={setOverrides}
        />
      )}
    </View>
  )

  return <>{isTray ? trayView : sectionView}</>
}
