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

import React, {useContext, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconCollapseLine, IconExpandLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {AllThreadsState, SearchContext} from '../../utils/constants'
import PropTypes from 'prop-types'

const I18n = createI18nScope('discussions_posts')

export const ExpandCollapseThreadsButton = props => {
  const {setAllThreadsStatus, setExpandedThreads} = useContext(SearchContext)
  const buttonText =
    props.expandedLocked || props.isExpanded ? I18n.t('Collapse Threads') : I18n.t('Expand Threads')

  useEffect(() => {
    if (props.isExpanded) {
      setAllThreadsStatus(AllThreadsState.Expanded)
    }
    setTimeout(() => {
      setAllThreadsStatus(AllThreadsState.None)
    }, 0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleExpandCollapseClick = () => {
    props.onCollapseRepliesToggle(!props.isExpanded)
    setExpandedThreads([])
    setAllThreadsStatus(props.isExpanded ? AllThreadsState.Collapsed : AllThreadsState.Expanded)
    setTimeout(() => {
      setAllThreadsStatus(AllThreadsState.None)
    }, 0)
  }

  const button = (
    <Button
      display="block"
      onClick={handleExpandCollapseClick}
      renderIcon={
        props.expandedLocked || props.isExpanded ? <IconCollapseLine /> : <IconExpandLine />
      }
      data-testid="ExpandCollapseThreads-button"
      data-action-state={props.isExpanded ? 'collapseButton' : 'expandButton'}
      disabled={props.disabled || false}
    >
      {props.showText ? buttonText : null}
    </Button>
  )

  return props.tooltipEnabled ? (
    <Tooltip renderTip={buttonText} width="78px" data-testid="sortButtonTooltip">
      {button}
    </Tooltip>
  ) : (
    button
  )
}

ExpandCollapseThreadsButton.propTypes = {
  showText: PropTypes.bool,
  isExpanded: PropTypes.bool,
  onCollapseRepliesToggle: PropTypes.func,
  tooltipEnabled: PropTypes.bool,
  disabled: PropTypes.bool,
  expandedLocked: PropTypes.bool,
}
