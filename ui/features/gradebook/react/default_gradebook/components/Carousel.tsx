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

import React, {Component} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenStartLine, IconArrowOpenEndLine} from '@instructure/ui-icons'

type CarouselProps = {
  disabled: boolean
  displayLeftArrow: boolean
  displayRightArrow: boolean
  id: string
  leftArrowDescription: string
  onLeftArrowClick: () => void
  onRightArrowClick: () => void
  rightArrowDescription: string
  children: JSX.Element
}

export default class Carousel extends Component<CarouselProps> {
  leftArrow: HTMLElement | null = null

  rightArrow: HTMLElement | null = null

  componentDidUpdate(prevProps: CarouselProps) {
    const selectedLast = prevProps.displayRightArrow && !this.props.displayRightArrow
    const selectedFirst = prevProps.displayLeftArrow && !this.props.displayLeftArrow

    if (selectedFirst) {
      this.rightArrow?.focus()
    } else if (selectedLast) {
      this.leftArrow?.focus()
    }
  }

  handleLeftArrowClick = () => {
    this.props.onLeftArrowClick()
    this.leftArrow?.focus()
  }

  handleRightArrowClick = () => {
    this.props.onRightArrowClick()
    this.rightArrow?.focus()
  }

  render() {
    const leftArrow = (
      <IconButton
        data-testid="left-arrow-button"
        disabled={this.props.disabled}
        ref={button => {
          this.leftArrow = button
        }}
        color="secondary"
        onClick={this.handleLeftArrowClick}
        size="small"
        renderIcon={IconArrowOpenStartLine}
        screenReaderLabel={this.props.leftArrowDescription}
      />
    )

    const rightArrow = (
      <IconButton
        data-testid="right-arrow-button"
        disabled={this.props.disabled}
        ref={button => {
          this.rightArrow = button
        }}
        color="secondary"
        onClick={this.handleRightArrowClick}
        size="small"
        renderIcon={IconArrowOpenEndLine}
        screenReaderLabel={this.props.rightArrowDescription}
      />
    )

    return (
      <div id={this.props.id} className="carousel">
        <div className="left-arrow-button-container">
          {this.props.displayLeftArrow && leftArrow}
        </div>

        <div style={{flex: 1, minWidth: 0}}>{this.props.children}</div>

        <div className="right-arrow-button-container">
          {this.props.displayRightArrow && rightArrow}
        </div>
      </div>
    )
  }
}

Carousel.defaultProps = {
  id: null,
}
