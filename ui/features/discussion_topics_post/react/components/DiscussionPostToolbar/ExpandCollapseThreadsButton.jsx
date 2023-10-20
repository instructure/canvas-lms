/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useContext} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconCollapseLine, IconExpandLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {AllThreadsState, SearchContext} from '../../utils/constants'
import PropTypes from 'prop-types'

const I18n = useI18nScope('discussions_posts')

export const ExpandCollapseThreadsButton = props => {
  const {setAllThreadsStatus, expandedThreads, setExpandedThreads} = useContext(SearchContext)

  const isExpanded = expandedThreads.length > 0
  const buttonText = isExpanded ? I18n.t('Collapse Threads') : I18n.t('Expand Threads')
  return (
    <Tooltip renderTip={buttonText} width="78px" data-testid="sortButtonTooltip">
      <Button
        onClick={() => {
          if (isExpanded) {
            setExpandedThreads([])
            setAllThreadsStatus(AllThreadsState.Collapsed)
          } else {
            setAllThreadsStatus(AllThreadsState.Expanded)
          }

          setTimeout(() => {
            setAllThreadsStatus(AllThreadsState.None)
          }, 0)
        }}
        renderIcon={isExpanded ? <IconExpandLine /> : <IconCollapseLine />}
        data-testid="ExpandCollapseThreads-button"
      >
        {props.showText ? buttonText : null}
      </Button>
    </Tooltip>
  )
}

ExpandCollapseThreadsButton.propTypes = {
  showText: PropTypes.bool,
}
