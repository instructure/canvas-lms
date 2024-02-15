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

const I18n = useI18nScope('rubrics-list-table')

export type RubricPopoverProps = {
  rubricId: string
}

export const RubricPopover = ({rubricId}: RubricPopoverProps) => {
  const navigate = useNavigate()
  const [isOpen, setIsOpen] = useState(false)

  return (
    <Popover
      renderTrigger={
        <IconButton
          renderIcon={IconMoreLine}
          screenReaderLabel={I18n.t('Rubric Options')}
          data-testid={`rubric-options-${rubricId}-button`}
        />
      }
      shouldRenderOffscreen={false}
      on="click"
      placement="bottom center"
      constrain="window"
      withArrow={false}
      isShowingContent={isOpen}
      onShowContent={() => {
        setIsOpen(true)
      }}
      onHideContent={() => {
        setIsOpen(false)
      }}
    >
      <Menu>
        <Menu.Item data-testid="edit-rubric-button" onClick={() => navigate(`./${rubricId}`)}>
          {I18n.t('Edit')}
        </Menu.Item>
        <Menu.Item data-testid="duplicate-rubric-button" onClick={() => {}}>
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
        <Menu.Item data-testid="delete-rubric-button" onClick={() => {}}>
          {I18n.t('Delete')}
        </Menu.Item>
      </Menu>
    </Popover>
  )
}
