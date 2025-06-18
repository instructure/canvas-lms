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

import React from 'react'
import {func} from 'prop-types'

export default class ColumnHeader<Props, State> extends React.Component<Props, State> {
  optionsMenuTrigger: any

  static propTypes = {
    addGradebookElement: func,
    removeGradebookElement: func,
    onHeaderKeyDown: func,
  }

  static defaultProps = {
    addGradebookElement() {},
    removeGradebookElement() {},
    onHeaderKeyDown() {},
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    this.handleBlur = this.handleBlur.bind(this)
    this.handleFocus = this.handleFocus.bind(this)
    this.handleKeyDown = this.handleKeyDown.bind(this)

    this.state = {
      // @ts-expect-error
      hasFocus: false,
      menuShown: false,
      skipFocusOnClose: false,
    }
  }

  // @ts-expect-error
  bindFlyoutMenu = (ref, name: string) => {
    if (ref) {
      // @ts-expect-error
      this[name] = ref
      // @ts-expect-error
      this.props.addGradebookElement(ref)
      ref.addEventListener('keydown', this.handleMenuKeyDown)
      // @ts-expect-error
    } else if (this[name]) {
      // @ts-expect-error
      this.props.removeGradebookElement(this[name])
    }
  }

  // @ts-expect-error
  bindSortByMenuContent = ref => {
    this.bindFlyoutMenu(ref, 'sortByMenuContent')
  }

  // @ts-expect-error
  bindOptionsMenuContent = ref => {
    this.bindFlyoutMenu(ref, 'optionsMenuContent')
  }

  focusAtStart = () => {
    if (this.optionsMenuTrigger) {
      this.optionsMenuTrigger.focus()
    }
  }

  focusAtEnd = () => {
    if (this.optionsMenuTrigger) {
      this.optionsMenuTrigger.focus()
    }
  }

  handleBlur() {
    // @ts-expect-error
    this.setState({hasFocus: false})
  }

  handleFocus() {
    // @ts-expect-error
    this.setState({hasFocus: true})
  }

  onToggle = (menuShown: boolean) => {
    const newState = {menuShown}
    let callback

    // @ts-expect-error
    if (this.state.menuShown && !menuShown) {
      // @ts-expect-error
      if (this.state.skipFocusOnClose) {
        // @ts-expect-error
        newState.skipMenuOnClose = false
      } else {
        callback = this.focusAtEnd
      }
    }

    // @ts-expect-error
    if (!this.state.menuShown && menuShown) {
      // @ts-expect-error
      newState.skipFocusOnClose = false
    }

    // @ts-expect-error
    this.setState(newState, callback)
  }

  handleMenuKeyDown = (event: React.KeyboardEvent) => {
    if (event.which === 9) {
      // Tab
      // @ts-expect-error
      this.setState({menuShown: false, skipFocusOnClose: true})
      // @ts-expect-error
      this.props.onHeaderKeyDown(event)
      return false
    }
    return true
  }

  handleKeyDown(event: React.KeyboardEvent) {
    if (document.activeElement === this.optionsMenuTrigger) {
      if (event.which === 13) {
        // Enter
        this.optionsMenuTrigger.click()
        return false // prevent Grid behavior
      }
    }

    return undefined
  }
}
