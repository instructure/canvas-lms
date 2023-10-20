/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, string} from 'prop-types'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('assignment')

function renderLink(anchorProps) {
  // This uses a plain <a /> rather than Instructure-UI's <Link /> because
  // <Tooltip /> and disabled <Link /> currently do not work together.
  return (
    <a rel="noopener noreferrer" target="_blank" {...anchorProps}>
      {I18n.t('SpeedGrader™')}
    </a>
  )
}

function SpeedGraderLink(props) {
  const className = props.className ? `icon-speed-grader ${props.className}` : 'icon-speed-grader'
  let anchorProps = {
    className,
    href: props.href,
  }

  if (props.disabled) {
    anchorProps = {
      ...anchorProps,
      'aria-disabled': 'true',
      'aria-describedby': props.disabledTip,
      onClick: event => {
        event.preventDefault()
      },
      role: 'button',
      style: {opacity: 0.5},
    }
  }

  return props.disabled ? (
    <Tooltip placement="bottom" renderTip={props.disabledTip} color="primary">
      {renderLink(anchorProps)}
    </Tooltip>
  ) : (
    renderLink(anchorProps)
  )
}

SpeedGraderLink.propTypes = {
  className: string,
  disabled: bool.isRequired,
  href: string.isRequired,
  disabledTip: string,
}

export default SpeedGraderLink
