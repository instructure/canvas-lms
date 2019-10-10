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

/*
 * This component is a near verbatim copy of
 * canvas-lms/packages/canvas-planner/src/components/ShowOnFocusButton
 * which is necessary until we have a package for sharing components
 * among canvas' sub-packages.
 */
import React, {Component} from 'react'
import {node, object} from 'prop-types'

import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y'

export default class ShowOnFocusButton extends Component {
  static propTypes = {
    buttonProps: object,
    srProps: object,
    children: node.isRequired
  }

  static defaultProps = {
    buttonRef: () => {}
  }

  state = {
    visible: false
  }

  handleFocus = () => {
    this.setState(
      {
        visible: true
      },
      () => {
        if (!this.btnRef.focused) {
          this.btnRef.focus()
        }
      }
    )
  }

  handleBlur = () => {
    this.setState({
      visible: false
    })
  }

  focus() {
    this.btnRef.focus()
  }

  renderButton() {
    const {buttonProps, children} = this.props
    return (
      <Button
        data-testid="ShowOnFocusButton__button"
        variant="link"
        ref={btn => {
          this.btnRef = btn
        }}
        onFocus={this.handleFocus}
        onBlur={this.handleBlur}
        {...buttonProps}
      >
        {children}
      </Button>
    )
  }

  renderInvisibleButton() {
    const {srProps} = this.props
    return (
      <ScreenReaderContent {...srProps} data-testid="ShowOnFocusButton__sronly">
        {this.renderButton()}
      </ScreenReaderContent>
    )
  }

  render() {
    if (this.state.visible) {
      return this.renderButton()
    } else {
      return this.renderInvisibleButton()
    }
  }
}
