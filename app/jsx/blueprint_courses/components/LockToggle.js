/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!blueprint_courses'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import IconLockSolid from 'instructure-icons/lib/Solid/IconLockSolid'
import IconUnlockSolid from 'instructure-icons/lib/Solid/IconUnlockSolid'

export default class LockToggle extends Component {
  static propTypes = {
    isLocked: PropTypes.bool.isRequired,
    isToggleable: PropTypes.bool.isRequired,
    onClick: PropTypes.func,
  }

  static defaultProps = {
    onClick: () => {},
  }

  static setupRootNode (wrapperSelector, childIndex, cb) {
    const toggleNode = document.createElement('span')
    // sometimes we have to wait for the DOM to settle down first
    const intId = setInterval(() => {
      const wrapperNode = document.querySelector(wrapperSelector)
      if (wrapperNode) {
        clearInterval(intId)
        wrapperNode.insertBefore(toggleNode, wrapperNode.childNodes[childIndex])
        cb(toggleNode)
      }
    }, 200)
  }

  getToggleComponent () {
    if (this.props.isToggleable) {
      const variant = this.props.isLocked ? 'primary' : 'default'
      const srLabel = this.props.isLocked ? I18n.t('Locked. Click to unlock.') : I18n.t('Unlocked. Click to lock.')

      return ({ children }) => (
        <Button variant={variant} onClick={this.props.onClick} aria-pressed={this.props.isLocked} aria-label={srLabel}>
          {children}
          <ScreenReaderContent>{srLabel}</ScreenReaderContent>
        </Button>
      )
    }

    return ({ children }) => (
      <Typography size="small" color="brand">
        &nbsp;{children}&nbsp;
      </Typography>
    )
  }

  render () {
    const Icon = this.props.isLocked ? IconLockSolid : IconUnlockSolid
    const Toggle = this.getToggleComponent()
    const text = this.props.isLocked ? I18n.t('Locked') : I18n.t('Unlocked')

    return (
      <Toggle>
        <span className="bpc-lock-toggle">
          <span style={{verticalAlign: 'sub', lineHeight: '100%'}}>
            <Icon width="1.5em" height="1.5em" />
          </span>
          &nbsp;{text}
        </span>
      </Toggle>
    )
  }
}
