/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import React from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'

export function ToggleButton({...props}) {
  return (
    <Tooltip
      renderTip={props.isEnabled ? props.enabledTooltipText : props.disabledTooltipText}
      placement="top"
      on={['hover', 'focus']}
    >
      <IconButton
        onClick={props.onClick}
        shape="circle"
        size="small"
        withBackground={false}
        withBorder={false}
        {...getButtonProps(props)}
        interaction={props.interaction}
      />
    </Tooltip>
  )
}

const getButtonProps = props => {
  return props.isEnabled
    ? {
        renderIcon: props.enabledIcon,
        color: 'success',
        screenReaderLabel: props.enabledScreenReaderLabel,
      }
    : {
        renderIcon: props.disabledIcon,
        color: 'secondary',
        screenReaderLabel: props.disabledScreenReaderLabel,
      }
}

ToggleButton.propTypes = {
  interaction: PropTypes.string,
  isEnabled: PropTypes.bool.isRequired,
  enabledIcon: PropTypes.node.isRequired,
  disabledIcon: PropTypes.node.isRequired,
  enabledTooltipText: PropTypes.string.isRequired,
  disabledTooltipText: PropTypes.string.isRequired,
  enabledScreenReaderLabel: PropTypes.string.isRequired,
  disabledScreenReaderLabel: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
}

export default ToggleButton
