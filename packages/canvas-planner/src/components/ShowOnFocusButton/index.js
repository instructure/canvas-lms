/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, { Component } from 'react';
import { findDOMNode } from 'react-dom';
import { node, object, func } from 'prop-types';

import themeable from '@instructure/ui-themeable/lib';
import Button from '@instructure/ui-core/lib/components/Button';
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent';

import styles from './styles.css';
import theme from './theme.js';

class ShowOnFocusButton extends Component {

  static propTypes = {
    buttonProps: object,
    srProps: object,
    children: node.isRequired,
    buttonRef: func
  };

  static defaultProps = {
    buttonRef: () =>{}
  };

  constructor (props) {
    super(props);
    this.state = {
      visible: false
    };
  }

  handleFocus = (e) => {
    this.setState({
      visible: true
    }, () => {
      // eslint-disable-next-line react/no-find-dom-node
      findDOMNode(this.btnRef).focus();
    });
  }

  handleBlur = (e) => {
    this.setState({
      visible: false
    });
  }

  renderButton () {
    const { buttonProps, children } = this.props;
    return (
      <Button
        variant="link"
        buttonRef={(btn) => { this.btnRef = btn; this.props.buttonRef(btn); }}
        onFocus={this.handleFocus}
        onBlur={this.handleBlur}
        {...buttonProps}
      >
        {children}
      </Button>
    );
  }

  renderInvisibleButton () {
    const { srProps } = this.props;
    return (
      <ScreenReaderContent {...srProps}>
        {this.renderButton()}
      </ScreenReaderContent>
    );
  }

  render () {
    if (this.state.visible) {
      return this.renderButton();
    } else {
      return this.renderInvisibleButton();
    }
  }
}

export default themeable(theme, styles)(ShowOnFocusButton);
