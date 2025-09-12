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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Popover} from '@instructure/ui-popover'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {useState} from 'react'
import LoadingIndicator from '@canvas/loading-indicator'
import type {GetRubricOutcomeQuery} from '@canvas/graphql/codegen/graphql'
import {OutcomePopoverDisplay} from './OutcomePopoverDisplay'

type OutcomePopoverProps = {
  outcome?: GetRubricOutcomeQuery['learningOutcome']
  renderTrigger: React.ReactNode
}

const I18n = createI18nScope('rubrics-assessment-outcome')

export const OutcomePopover = ({outcome, renderTrigger}: OutcomePopoverProps) => {
  const [isShowingContent, setIsShowingContent] = useState(false)

  return (
    <Popover
      renderTrigger={renderTrigger}
      isShowingContent={isShowingContent}
      onShowContent={() => setIsShowingContent(true)}
      onHideContent={() => setIsShowingContent(false)}
      on="click"
      screenReaderLabel={I18n.t('Rubric Outcome Popover')}
      shouldContainFocus
      shouldReturnFocus
      shouldCloseOnDocumentClick
      offsetY="16px"
    >
      <View padding="medium" display="block" as="form">
        <CloseButton
          placement="end"
          offset="small"
          onClick={() => setIsShowingContent(false)}
          screenReaderLabel={I18n.t('Close')}
        />
        {!outcome ? (
          <View as="div" textAlign="center" padding="medium">
            <LoadingIndicator />
          </View>
        ) : (
          <OutcomePopoverDisplay outcome={outcome} />
        )}
      </View>
    </Popover>
  )
}
