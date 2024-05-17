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

import React, {useEffect, useRef, useState} from 'react'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {View} from '@instructure/ui-view'
import {IconEditLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import ReactDOM from 'react-dom'
import {
  DateDetailsPayload,
  ItemAssignToCardSpec,
} from '@canvas/context-modules/differentiated-modules/react/Item/types'
import {
  generateDateDetailsPayload,
  generateDefaultCard,
} from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'

const I18n = useI18nScope('pages_edit')

interface Props {
  pageName?: string
  pageId?: string
  onSync: (overrides: DateDetailsPayload) => void
}

const AssignToOption = (props: Props) => {
  const [open, setOpen] = useState(false)
  const [checkPoint, setCheckPoint] = useState<ItemAssignToCardSpec[] | undefined>(undefined)
  const [disabledOptionIds, setDisabledOptionIds] = useState<string[]>([])
  const [showPendingChangesPill, setShowPendingChangesPill] = useState(false)
  const linkRef = useRef<Link | null>(null)
  const itemName =
    (document.getElementById('wikipage-title-input') as HTMLInputElement)?.value ?? props.pageName

  const handleOpen = () => setOpen(true)

  const handleClose = () => setOpen(false)

  const handleDismiss = () => {
    handleClose()
  }

  useEffect(() => {
    if (props.pageId === undefined) {
      const defaultCard = generateDefaultCard()
      setCheckPoint([defaultCard])
      setDisabledOptionIds(defaultCard.selectedAssigneeIds)
    }
  }, [props.pageId])

  const handleSave = (
    assignToCards: ItemAssignToCardSpec[],
    hasModuleOverrides: boolean,
    deletedModuleAssignees: string[]
  ) => {
    const hasChanges =
      assignToCards.some(({highlightCard}) => highlightCard) ||
      (checkPoint !== undefined && assignToCards.length < Object.entries(checkPoint).length)
    setShowPendingChangesPill(hasChanges)
    const filteredCards = assignToCards.filter(
      card =>
        [null, undefined, ''].includes(card.contextModuleId) ||
        (card.contextModuleId !== null && card.isEdited)
    )
    const overrides = generateDateDetailsPayload(
      filteredCards,
      hasModuleOverrides,
      deletedModuleAssignees
    )
    props.onSync(overrides)
    setCheckPoint(assignToCards)
    handleClose()
  }

  return (
    <>
      <View display="flex">
        <View as="div" margin="none none" width="25px">
          <IconEditLine size="x-small" color="primary" />
        </View>
        <Link
          margin="none none"
          data-testid="manage-assign-to"
          isWithinText={false}
          ref={ref => (linkRef.current = ref)}
          onClick={() => (open ? handleClose() : handleOpen())}
        >
          <View as="div">
            {I18n.t('Manage Assign To')}
            {showPendingChangesPill && (
              <Pill data-testid="pending_changes_pill" color="info" margin="auto small">
                {I18n.t('Pending Changes')}
              </Pill>
            )}
          </View>
        </Link>
      </View>
      <ItemAssignToTray
        open={open}
        onClose={handleClose}
        onDismiss={handleDismiss}
        courseId={ENV.COURSE_ID}
        itemName={itemName}
        itemType="page"
        iconType="page"
        itemContentId={props.pageId}
        useApplyButton={true}
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        removeDueDateInput={true}
        onSave={handleSave}
        defaultCards={checkPoint}
        defaultDisabledOptionIds={disabledOptionIds}
        onInitialStateSet={setCheckPoint}
      />
    </>
  )
}

export const renderAssignToTray = (el: HTMLElement, props: Props) => {
  if (el) {
    ReactDOM.render(<AssignToOption {...props} />, el)
  }
  return <AssignToOption {...props} />
}
