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

import React from 'react'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

interface ReorderBlocksPopoverProps {
  isShowingContent: boolean
  onShowContent: () => void
  onHideContent: () => void
  renderTrigger: (props: any) => React.ReactElement
}

export const ReorderBlocksPopover = ({
  isShowingContent,
  onShowContent,
  onHideContent,
  renderTrigger,
}: ReorderBlocksPopoverProps) => {
  return (
    <Popover
      isShowingContent={isShowingContent}
      onShowContent={onShowContent}
      onHideContent={onHideContent}
      on="click"
      placement="end top"
      shouldContainFocus
      shouldReturnFocus
      shouldCloseOnDocumentClick={true}
      constrain="window"
      renderTrigger={renderTrigger}
      screenReaderLabel={I18n.t('Reorder blocks')}
      data-testid="reorder-blocks-popover"
    >
      <View as="div" width="30rem" aria-labelledby="reorder-blocks-heading">
        <Flex direction="column" padding="medium">
          <Flex justifyItems="space-between">
            <Heading
              level="h2"
              margin="0"
              id="reorder-blocks-heading"
              data-testid="reorder-blocks-popover-header"
            >
              {I18n.t('Reorder blocks')}
            </Heading>
            <CloseButton
              screenReaderLabel={I18n.t('Close')}
              onClick={onHideContent}
              data-testid="reorder-blocks-close-button"
            />
          </Flex>

          <View as="div" margin="small 0 0 0" />
        </Flex>
      </View>
    </Popover>
  )
}
