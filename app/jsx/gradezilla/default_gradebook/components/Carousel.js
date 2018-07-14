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

import React, { Component } from 'react';
import { bool, func, node, string } from 'prop-types';
import Button from '@instructure/ui-buttons/lib/components/Button';
import ArrowOpenStart from '@instructure/ui-icons/lib/Line/IconArrowOpenStart';
import ArrowOpenEnd from '@instructure/ui-icons/lib/Line/IconArrowOpenEnd';

export default class Carousel extends Component {
  componentDidUpdate (prevProps) {
    const selectedLast = prevProps.displayRightArrow && !this.props.displayRightArrow;
    const selectedFirst = prevProps.displayLeftArrow && !this.props.displayLeftArrow;

    if (selectedFirst) {
      this.rightArrow.focus();
    } else if (selectedLast) {
      this.leftArrow.focus();
    }
  }

  handleLeftArrowClick = () => {
    this.props.onLeftArrowClick();
    this.leftArrow.focus();
  }

  handleRightArrowClick = () => {
    this.props.onRightArrowClick();
    this.rightArrow.focus();
  }

  render () {
    const leftArrow = (
      <Button
        disabled={this.props.disabled}
        ref={(button) => { this.leftArrow = button }}
        variant="icon"
        onClick={this.handleLeftArrowClick}
        size="small"
      >
        <ArrowOpenStart title={this.props.leftArrowDescription} />
      </Button>
    );

    const rightArrow = (
      <Button
        disabled={this.props.disabled}
        ref={(button) => { this.rightArrow = button }}
        variant="icon"
        onClick={this.handleRightArrowClick}
        size="small"
      >
        <ArrowOpenEnd title={this.props.rightArrowDescription} />
      </Button>
    );

    return (
      <div id={this.props.id} className="carousel">
        <div className="left-arrow-button-container">
          { this.props.displayLeftArrow && leftArrow }
        </div>

        <div style={{ flex: 1 }}>
          {this.props.children}
        </div>

        <div className="right-arrow-button-container">
          { this.props.displayRightArrow && rightArrow }
        </div>
      </div>
    );
  }
}

Carousel.defaultProps = {
  id: null,
  showBorderBottom: true
};

Carousel.propTypes = {
  id: string,
  children: node.isRequired,
  disabled: bool.isRequired,
  displayLeftArrow: bool.isRequired,
  displayRightArrow: bool.isRequired,
  onLeftArrowClick: func.isRequired,
  onRightArrowClick: func.isRequired,
  leftArrowDescription: string.isRequired,
  rightArrowDescription: string.isRequired
};
