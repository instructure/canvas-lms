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

import {useState} from 'react'
import {ToolbarButton} from './ToolbarButton'
import {IconSortLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ReorderBlocksPopover} from './ReorderBlocksPopover'

const I18n = createI18nScope('block_content_editor')

export const ReorderBlocksButton = (props: {blockCount: number}) => {
  const [isPopoverOpen, setIsPopoverOpen] = useState(false)
  const isDisabled = props.blockCount < 2

  const handleButtonClick = () => {
    if (!isDisabled) {
      setIsPopoverOpen(true)
    }
  }

  const handleShowContent = () => {
    setIsPopoverOpen(true)
  }

  const handleHideContent = () => {
    setIsPopoverOpen(false)
  }

  return (
    <ReorderBlocksPopover
      isShowingContent={isPopoverOpen}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      renderTrigger={() => (
        <div>
          <ToolbarButton
            interaction={isDisabled ? 'disabled' : 'enabled'}
            screenReaderLabel={I18n.t('Reorder blocks')}
            renderIcon={<IconSortLine />}
            onClick={handleButtonClick}
            data-testid="reorder-blocks-button"
          />
        </div>
      )}
    />
  )
}
