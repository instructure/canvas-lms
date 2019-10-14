/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {element, func, oneOf, oneOfType, string} from 'prop-types'
import React, {Component} from 'react'

import ButtonContext from '../../../student/components/Context'
import classNames from 'classnames'
import I18n from 'i18n!assignments_2_shared_Steps_StepItem'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {
  IconArrowOpenEndSolid,
  IconArrowOpenStartSolid,
  IconCheckMarkSolid,
  IconLockSolid,
  IconPlusSolid
} from '@instructure/ui-icons'
import {omitProps} from '@instructure/ui-react-utils'
import {px} from '@instructure/ui-utils'
import {ScreenReaderContent} from '@instructure/ui-a11y'

class StepItem extends Component {
  static propTypes = {
    status: oneOf(['button', 'complete', 'in-progress', 'unavailable']),
    label: oneOfType([func, string, element]).isRequired,
    icon: element,
    pinSize: string,
    placement: oneOf(['first', 'last', 'interior'])
  }

  static defaultProps = {
    placement: 'interior'
  }

  /**
   * renderButton renders a small, circular, gray button. This button
   * style is used for the Previous, New Attempt, and Next buttons in
   * the Assignments 2 pizzatracker, which are used to navigate between
   * submissions for a single assignment.
   *
   * @param ButtonIcon  An instUI icon corresponding to the rendered
   *                    button's purpose
   * @param action      The action to be performed when the rendered
   *                    button is clicked
   * @param a11yMessage The message to be read by the screen reader
   *                    when focus is on the rendered button
   */
  renderButton(ButtonIcon, action, a11yMessage) {
    const icon = <ButtonIcon size="x-small" />
    return (
      <div>
        <ApplyTheme
          theme={{
            [Button.theme]: {
              iconColor: '#C1C8CD',
              borderRadius: '2rem'
            }
          }}
        >
          <Button variant="icon" icon={icon} size="small" onClick={action}>
            <ScreenReaderContent>{a11yMessage} </ScreenReaderContent>
          </Button>
        </ApplyTheme>
      </div>
    )
  }

  renderIcon(context) {
    const icon = this.props.icon
    const status = this.props.status

    if (!icon && status === 'button') {
      switch (this.props.label) {
        case 'Previous':
          return this.renderButton(
            IconArrowOpenStartSolid,
            context.prevButtonAction,
            I18n.t('View Previous Submission')
          )
        case 'Next':
          return this.renderButton(
            IconArrowOpenEndSolid,
            context.nextButtonAction,
            I18n.t('View Next Submission')
          )
        case 'New Attempt':
          return this.renderButton(
            IconPlusSolid,
            context.startNewAttemptAction,
            I18n.t('Create New Attempt')
          )
        default:
          return null
      }
    } else {
      return <span aria-hidden>{this.selectIcon(icon, status)}</span>
    }
  }

  selectIcon(Icon, status) {
    if (!Icon && status === 'complete') {
      return <IconCheckMarkSolid color="primary-inverse" />
    } else if (!Icon && status === 'unavailable') {
      return <IconLockSolid color="error" />
    } else if (typeof Icon === 'function') {
      return <Icon />
    } else if (Icon) {
      return Icon
    } else {
      return null
    }
  }

  pinSize = () => {
    switch (this.props.status) {
      case 'complete':
        return Math.round(px(this.props.pinSize) / 1.5)
      case 'unavailable':
        return Math.round(px(this.props.pinSize) / 1.2)
      case 'button':
        return Math.round(px(this.props.pinSize) / 1.05)
      case 'in-progress':
        return px(this.props.pinSize)
      default:
        return Math.round(px(this.props.pinSize) / 2.25)
    }
  }

  renderLabel = () => {
    const {label, status} = this.props
    if (typeof label === 'function') {
      return label(status)
    } else {
      return label
    }
  }

  render() {
    const {status, placement} = this.props

    const classes = {
      'step-item-step': true,
      [status]: true,
      [`placement--${placement}`]: true
    }

    return (
      <span
        className={classNames(classes)}
        data-testid="step-item-step"
        {...omitProps(this.props, StepItem.propTypes)}
      >
        <span
          className="pinLayout"
          style={{
            height: px(this.props.pinSize)
          }}
        >
          <span
            style={{
              width: `${this.pinSize()}px`,
              height: `${this.pinSize()}px`
            }}
            className="step-item-pin"
          >
            <ButtonContext.Consumer>{context => this.renderIcon(context)}</ButtonContext.Consumer>
          </span>
        </span>
        <span className="step-item-label" aria-hidden={this.props.status === 'button'}>
          {this.renderLabel()}
        </span>
      </span>
    )
  }
}

export default StepItem
