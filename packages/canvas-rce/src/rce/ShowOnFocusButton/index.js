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
import {func, node, oneOfType, string} from 'prop-types'

import {IconButton} from '@instructure/ui-buttons'

const hideStyle = {
  position: 'absolute',
  left: '-9999px',
}

export default class ShowOnFocusButton extends Component {
  static propTypes = {
    children: oneOfType([node, func]).isRequired, // func === functional component
    onClick: func,
    screenReaderLabel: string.isRequired,
    margin: string,
    id: string.isRequired,
  }

  state = {
    visible: false,
  }

  handleFocus = () => {
    this.setState({visible: true})
  }

  handleBlur = () => {
    this.setState({visible: false})
  }

  focus() {
    this.btnRef.focus()
    this.setState({visible: true})
  }

  renderButton() {
    return (
      <IconButton
        id={this.props.id}
        data-testid="ShowOnFocusButton__button"
        color="primary"
        aria-haspopup="dialog"
        margin={this.props.margin}
        ref={btn => {
          this.btnRef = btn
        }}
        onFocus={this.handleFocus}
        onBlur={this.handleBlur}
        onClick={this.props.onClick}
        screenReaderLabel={this.props.screenReaderLabel}
        withBackground={false}
        withBorder={false}
      >
        {this.props.children}
      </IconButton>
    )
  }

  render() {
    return (
      <div data-testid="ShowOnFocusButton__wrapper" style={this.state.visible ? null : hideStyle}>
        {this.renderButton()}
      </div>
    )
  }
}
