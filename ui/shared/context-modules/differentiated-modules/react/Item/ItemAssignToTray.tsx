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

import React, {useCallback, useMemo, useRef, useState} from 'react'
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
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {DateDetails, DateLockTypes, ItemAssignToCardSpec} from './types'
import {type ItemAssignToCardRef} from './ItemAssignToCard'
import TrayFooter from '../Footer'
import {generateDateDetailsPayload, itemTypeToApiURL} from '../../utils/assignToHelper'
import {Text} from '@instructure/ui-text'
import {Alert} from '@instructure/ui-alerts'
import type {IconType, ItemType} from '../types'
import ItemAssignToTrayContent from './ItemAssignToTrayContent'
import CoursePacingNotice from '@canvas/due-dates/react/CoursePacingNotice'
import useFetchAssignees from '../../utils/hooks/useFetchAssignees'

const I18n = useI18nScope('differentiated_modules')

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
    deletedModuleAssignees: String[]
  ) => void
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
    deletedAssignee: Record<string, any>[]
  ) => void
  onDatesChange?: (cardId: string, dateType: string, newDate: string) => void
  onCardRemove?: (cardId: string) => void
  onInitialStateSet?: (cards: ItemAssignToCardSpec[]) => void
  postToSIS?: boolean
}

export default function ItemAssignToTray({
  open,
  onSave,
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
}: ItemAssignToTrayProps) {
  const isPacedCourse = ENV.IN_PACED_COURSE
  const initialLoadRef = useRef(false)
  const cardsRefs = useRef<{[cardId: string]: ItemAssignToCardRef}>({})
  const [isLoading, setIsLoading] = useState(false)
  const [disabledOptionIds, setDisabledOptionIds] = useState<string[]>(
    defaultDisabledOptionIds ?? []
  )
  const [assignToCards, setAssignToCards] = useState<ItemAssignToCardSpec[]>(defaultCards ?? [])
  const [hasModuleOverrides, setHasModuleOverrides] = useState(false)
  const [moduleAssignees, setModuleAssignees] = useState<string[]>([])
  const [groupCategoryId, setGroupCategoryId] = useState<string | null>(defaultGroupCategoryId)
  const [overridesFetched, setOverridesFetched] = useState(
    defaultCards !== undefined && defaultCards.length > 0
  )
  const [blueprintDateLocks, setBlueprintDateLocks] = useState<DateLockTypes[] | undefined>(
    undefined
  )

  const everyoneOption = useMemo(() => {
    const hasOverrides =
      (disabledOptionIds.length === 1 && !disabledOptionIds.includes('everyone')) ||
      disabledOptionIds.length > 1 ||
      assignToCards.length > 1
    return getEveryoneOption(hasOverrides)
  }, [disabledOptionIds, assignToCards])

  const handleDismiss = useCallback(() => {
    if (defaultCards) {
      setAssignToCards(defaultCards)
    }
    onDismiss()
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
    requiredOptions: disabledOptionIds,
    onError: handleDismiss,
  })

  const handleUpdate = useCallback(() => {
    const hasErrors = assignToCards.some(card => !card.isValid)
    // If a card has errors it should not save and the respective card should be focused
    if (hasErrors) {
      const firstCardWithError = assignToCards.find(card => !card.isValid)
      if (!firstCardWithError) return
      const firstCardWithErrorRef = cardsRefs.current[firstCardWithError.key]

      Object.values(cardsRefs.current).forEach(c => c.showValidations())
      firstCardWithErrorRef?.focusInputs()
      return
    }
    // compare original module assignees to see if they were removed for unassign_item overrides
    const deletedModuleAssignees = moduleAssignees.filter(
      override => !disabledOptionIds.includes(override)
    )

    if (onSave !== undefined) {
      onSave(assignToCards, hasModuleOverrides, deletedModuleAssignees)
      return
    }
    const filteredCards = assignToCards.filter(
      card =>
        [null, undefined, ''].includes(card.contextModuleId) ||
        (card.contextModuleId !== null && card.isEdited)
    )
    const payload = generateDateDetailsPayload(
      filteredCards,
      hasModuleOverrides,
      deletedModuleAssignees
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
    assignToCards,
    moduleAssignees,
    onSave,
    hasModuleOverrides,
    itemContentId,
    disabledOptionIds,
    courseId,
    itemType,
    itemName,
    handleDismiss,
  ])

  const allCardsValid = useCallback(() => {
    return assignToCards.every(card => card.isValid)
  }, [assignToCards])

  const renderPointsPossible = () =>
    pointsPossible === 1 ? I18n.t('1 pt') : I18n.t('%{pointsPossible} pts', {pointsPossible})

  function Header() {
    const icon = itemTypeToIcon(iconType)
    return (
      <Flex.Item margin="medium 0 small" padding="0 medium" width="100%">
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
    return (
      <Flex.Item data-testid="module-item-edit-tray-footer" width="100%">
        <TrayFooter
          disableSave={isPacedCourse}
          saveButtonLabel={useApplyButton ? I18n.t('Apply') : I18n.t('Save')}
          onDismiss={handleDismiss}
          onUpdate={handleUpdate}
          hasErrors={!allCardsValid()}
        />
      </Flex.Item>
    )
  }

  return (
    <Tray
      data-testid="module-item-edit-tray"
      onClose={onClose}
      onExited={onExited}
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
            onInitialStateSet={onInitialStateSet}
            defaultCards={defaultCards}
            defaultSectionId={defaultSectionId}
            defaultDisabledOptionIds={defaultDisabledOptionIds}
            onSave={onSave}
            onAddCard={onAddCard}
            onAssigneesChange={onAssigneesChange}
            onDatesChange={onDatesChange}
            onCardRemove={onCardRemove}
            assignToCards={assignToCards}
            setAssignToCards={setAssignToCards}
            blueprintDateLocks={blueprintDateLocks}
            setBlueprintDateLocks={setBlueprintDateLocks}
            handleDismiss={handleDismiss}
            hasModuleOverrides={hasModuleOverrides}
            setHasModuleOverrides={setHasModuleOverrides}
            cardsRefs={cardsRefs}
            setModuleAssignees={setModuleAssignees}
            disabledOptionIds={disabledOptionIds}
            setDisabledOptionIds={setDisabledOptionIds}
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
          />
        )}
        {Footer()}
      </Flex>
    </Tray>
  )
}
