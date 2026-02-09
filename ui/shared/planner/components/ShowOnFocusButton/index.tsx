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
import React, {Component} from 'react'
import {findDOMNode} from 'react-dom'
import {node, object, func} from 'prop-types'

import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export default class ShowOnFocusButton extends Component {
  static propTypes = {
    buttonProps: object,
    srProps: object,
    children: node.isRequired,
    elementRef: func,
  }

  static defaultProps = {
    elementRef: () => {},
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    this.state = {
      visible: false,
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleFocus = _ => {
    this.setState(
      {
        visible: true,
      },
      () => {
        // @ts-expect-error TS2339,TS2531 (typescriptify)
        findDOMNode(this.btnRef).focus()
      },
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleBlur = _ => {
    this.setState({
      visible: false,
    })
  }

  renderButton() {
    // @ts-expect-error TS2339 (typescriptify)
    const {buttonProps, children} = this.props
    return (
      <Link
        isWithinText={false}
        as="button"
        elementRef={btn => {
          // @ts-expect-error TS2339 (typescriptify)
          this.btnRef = btn
          // @ts-expect-error TS2339 (typescriptify)
          this.props.elementRef(btn)
        }}
        onFocus={this.handleFocus}
        onBlur={this.handleBlur}
        {...buttonProps}
      >
        {children}
      </Link>
    )
  }

  renderInvisibleButton() {
    // @ts-expect-error TS2339 (typescriptify)
    const {srProps} = this.props
    return (
      <ScreenReaderContent data-testid="screenreader-content" {...srProps}>
        {this.renderButton()}
      </ScreenReaderContent>
    )
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.state.visible) {
      return this.renderButton()
    } else {
      return this.renderInvisibleButton()
    }
  }
}
