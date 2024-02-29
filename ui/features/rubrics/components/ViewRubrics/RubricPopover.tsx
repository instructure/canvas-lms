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

import React, {useState} from 'react'
import {useNavigate} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {DuplicateRubricModal} from './DuplicateRubricModal'
import {DeleteRubricModal} from './DeleteRubricModal'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'

const I18n = useI18nScope('rubrics-list-table')

export type RubricPopoverProps = {
  id?: string
  title: string
  hidePoints?: boolean
  accountId?: string
  courseId?: string
  criteria?: RubricCriterion[]
  pointsPossible: number
  buttonDisplay?: string
  ratingOrder?: string
  hasRubricAssociations?: boolean
}

export const RubricPopover = ({
  id,
  title,
  hidePoints,
  accountId,
  courseId,
  criteria,
  pointsPossible,
  buttonDisplay,
  ratingOrder,
  hasRubricAssociations,
}: RubricPopoverProps) => {
  const navigate = useNavigate()
  const [isPopoverOpen, setPopoverIsOpen] = useState(false)
  const [isDuplicateRubricModalOpen, setIsDuplicateRubricModalOpen] = useState(false)
  const [isDeleteRubricModalOpen, setIsDeleteRubricModalOpen] = useState(false)

  return (
    <View>
      <DuplicateRubricModal
        isOpen={isDuplicateRubricModalOpen}
        onDismiss={() => setIsDuplicateRubricModalOpen(false)}
        setPopoverIsOpen={setPopoverIsOpen}
        title={title}
        id={id}
        hidePoints={hidePoints}
        criteria={criteria}
        pointsPossible={pointsPossible}
        buttonDisplay={buttonDisplay}
        ratingOrder={ratingOrder}
        accountId={accountId}
        courseId={courseId}
      />
      <DeleteRubricModal
        isOpen={isDeleteRubricModalOpen}
        onDismiss={() => setIsDeleteRubricModalOpen(false)}
        title={title}
        id={id}
        accountId={accountId}
        courseId={courseId}
        setPopoverIsOpen={setPopoverIsOpen}
      />
      <Popover
        renderTrigger={
          <IconButton
            renderIcon={IconMoreLine}
            screenReaderLabel={I18n.t('Rubric Options')}
            data-testid={`rubric-options-${id}-button`}
          />
        }
        shouldRenderOffscreen={false}
        on="click"
        placement="bottom center"
        constrain="window"
        withArrow={false}
        isShowingContent={isPopoverOpen}
        onShowContent={() => {
          setPopoverIsOpen(true)
        }}
        onHideContent={() => {
          setPopoverIsOpen(false)
        }}
      >
        <Menu>
          <Menu.Item data-testid="edit-rubric-button" onClick={() => navigate(`./${id}`)}>
            {I18n.t('Edit')}
          </Menu.Item>
          <Menu.Item
            data-testid="duplicate-rubric-button"
            onClick={() => setIsDuplicateRubricModalOpen(true)}
          >
            {I18n.t('Duplicate')}
          </Menu.Item>
          <Menu.Item data-testid="archive-rubric-button" onClick={() => {}}>
            {I18n.t('Archive')}
          </Menu.Item>
          <Menu.Item data-testid="download-rubric-button" onClick={() => {}}>
            {I18n.t('Download')}
          </Menu.Item>
          <Menu.Item data-testid="print-rubric-button" onClick={() => {}}>
            {I18n.t('Print')}
          </Menu.Item>
          <Menu.Item
            disabled={hasRubricAssociations}
            data-testid="delete-rubric-button"
            onClick={() => setIsDeleteRubricModalOpen(true)}
          >
            {I18n.t('Delete')}
          </Menu.Item>
        </Menu>
      </Popover>
    </View>
  )
}
