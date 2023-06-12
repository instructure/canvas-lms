// @ts-nocheck
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

  constructor(props) {
    super(props)

    this.handleBlur = this.handleBlur.bind(this)
    this.handleFocus = this.handleFocus.bind(this)
    this.handleKeyDown = this.handleKeyDown.bind(this)

    this.state = {
      hasFocus: false, // eslint-disable-line react/no-unused-state
      menuShown: false,
      skipFocusOnClose: false,
    }
  }

  bindFlyoutMenu = (ref, name: string) => {
    if (ref) {
      this[name] = ref
      this.props.addGradebookElement(ref)
      ref.addEventListener('keydown', this.handleMenuKeyDown)
    } else if (this[name]) {
      this.props.removeGradebookElement(this[name])
    }
  }

  bindSortByMenuContent = ref => {
    this.bindFlyoutMenu(ref, 'sortByMenuContent')
  }

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
    this.setState({hasFocus: false}) // eslint-disable-line react/no-unused-state
  }

  handleFocus() {
    this.setState({hasFocus: true}) // eslint-disable-line react/no-unused-state
  }

  onToggle = (menuShown: boolean) => {
    const newState = {menuShown}
    let callback

    if (this.state.menuShown && !menuShown) {
      if (this.state.skipFocusOnClose) {
        newState.skipMenuOnClose = false
      } else {
        callback = this.focusAtEnd
      }
    }

    if (!this.state.menuShown && menuShown) {
      newState.skipFocusOnClose = false
    }

    this.setState(newState, callback)
  }

  handleMenuKeyDown = (event: React.KeyboardEvent) => {
    if (event.which === 9) {
      // Tab
      this.setState({menuShown: false, skipFocusOnClose: true})
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
