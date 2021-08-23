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

import I18n from 'i18n!blueprint_coursesLockToggle'
import React, {Component} from 'react'
import PropTypes from 'prop-types'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'

import {IconBlueprintLockSolid, IconBlueprintSolid} from '@instructure/ui-icons'

import WithBreakpoints, {breakpointsShape} from 'with-breakpoints'

const modes = {
  ADMIN_LOCKED: {
    label: I18n.t('Locked'),
    icon: IconBlueprintLockSolid,
    tooltip: I18n.t('Unlock'),
    variant: 'primary'
  },
  ADMIN_UNLOCKED: {
    label: I18n.t('Blueprint'),
    icon: IconBlueprintSolid,
    tooltip: I18n.t('Lock'),
    variant: 'default'
  },
  ADMIN_WILLUNLOCK: {
    label: I18n.t('Blueprint'),
    icon: IconBlueprintSolid,
    tooltip: I18n.t('Unlock'),
    variant: 'default'
  },
  ADMIN_WILLLOCK: {
    label: I18n.t('Locked'),
    icon: IconBlueprintLockSolid,
    tooltip: I18n.t('Lock'),
    variant: 'primary'
  },
  TEACH_LOCKED: {
    label: I18n.t('Locked'),
    icon: IconBlueprintLockSolid
  },
  TEACH_UNLOCKED: {
    label: I18n.t('Blueprint'),
    icon: IconBlueprintSolid
  }
}

class LockToggle extends Component {
  static propTypes = {
    isLocked: PropTypes.bool.isRequired,
    isToggleable: PropTypes.bool,
    onClick: PropTypes.func,
    breakpoints: breakpointsShape
  }

  static defaultProps = {
    isToggleable: false,
    onClick: () => {},
    breakpoints: {}
  }

  static setupRootNode(wrapperSelector, childIndex, cb) {
    const toggleNode = document.createElement('span')
    toggleNode.className = 'bpc-lock-toggle-wrapper'
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

  constructor(props) {
    super(props)
    this.state = {}
    this.toggleBtnRef = null

    if (props.isToggleable) {
      this.state.mode = props.isLocked ? modes.ADMIN_LOCKED : modes.ADMIN_UNLOCKED
    } else {
      this.state.mode = props.isLocked ? modes.TEACH_LOCKED : modes.TEACH_UNLOCKED
    }
  }

  componentDidMount() {
    // Fixing the width of the Toggle button to the biggest possible label to avoid resizing the button
    const biggestLabelLength = Math.max(...Object.values(modes).map(mode => mode.label.length))

    if (this.toggleBtnRef) {
      this.toggleBtnRef.style.width = biggestLabelLength * 0.845 + 'em'
    }
  }

  onEnter = () => {
    if (this.props.isToggleable) {
      this.setState({
        mode: this.props.isLocked ? modes.ADMIN_WILLUNLOCK : modes.ADMIN_WILLLOCK
      })
    }
  }

  onExit = () => {
    if (this.props.isToggleable) {
      this.setState({
        mode: this.props.isLocked ? modes.ADMIN_LOCKED : modes.ADMIN_UNLOCKED
      })
    }
  }

  render() {
    const Icon = this.state.mode.icon
    const text = <span className="bpc-lock-toggle__label">{this.state.mode.label || '-'}</span>
    let toggle = null

    if (this.props.isToggleable) {
      const variant = this.state.mode.variant
      const tooltip = this.state.mode.tooltip
      const srLabel = this.props.isLocked
        ? I18n.t('Locked. Click to unlock.')
        : I18n.t('Unlocked. Click to lock.')

      toggle = (
        <Tooltip tip={tooltip} placement="top" variant="inverse" on={['hover', 'focus']}>
          {this.props.breakpoints.miniTablet ? (
            <Button
              id="lock-toggle-btn"
              elementRef={r => (this.toggleBtnRef = r)}
              variant={variant}
              onClick={this.props.onClick}
              onFocus={this.onEnter}
              onBlur={this.onExit}
              onMouseEnter={this.onEnter}
              onMouseLeave={this.onExit}
              aria-pressed={this.props.isLocked}
            >
              <Icon />
              <PresentationContent>{text}</PresentationContent>
              <ScreenReaderContent>{srLabel}</ScreenReaderContent>
            </Button>
          ) : (
            <IconButton
              color={variant === 'primary' ? variant : null}
              onClick={this.props.onClick}
              onFocus={this.onEnter}
              onBlur={this.onExit}
              onMouseEnter={this.onEnter}
              onMouseLeave={this.onExit}
              aria-pressed={this.props.isLocked}
              screenReaderLabel={srLabel}
            >
              <Icon />
            </IconButton>
          )}
        </Tooltip>
      )
    } else {
      toggle = (
        <span className="bpc__lock-no__toggle">
          <span className="bpc__lock-no__toggle-icon">
            <Icon />
          </span>
          <Text size="small">{text}</Text>
        </span>
      )
    }

    return <span className="bpc-lock-toggle">{toggle}</span>
  }
}

const LockToggleWithBreakpoints = WithBreakpoints(LockToggle)
LockToggleWithBreakpoints.setupRootNode = LockToggle.setupRootNode

export default LockToggleWithBreakpoints
