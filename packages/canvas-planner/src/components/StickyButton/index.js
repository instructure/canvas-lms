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
import classnames from 'classnames';
import themeable from '@instructure/ui-themeable/lib';
import { bool, func, node, number, string, oneOf } from 'prop-types';
import IconArrowUpSolid from '@instructure/ui-icons/lib/Solid/IconArrowUp';
import IconArrowDownLine from '@instructure/ui-icons/lib/Line/IconArrowDown';

import styles from './styles.css';
import theme from './theme.js';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';

class StickyButton extends Component {
  static propTypes = {
    id: string.isRequired,
    children: node.isRequired,
    onClick: func,
    disabled: bool,
    hidden: bool,
    direction: oneOf(['none', 'up', 'down']),
    className: string,
    zIndex: number,
    buttonRef: func,
    description: string,
  };

  static defaultProps = {
    direction: 'none',
    offset: '0',
    className: ''
  };

  handleClick = (e) => {
    const {
      disabled,
      onClick
    } = this.props;

    if (disabled) {
      e.preventDefault();
      e.stopPropagation();
    } else if (typeof onClick === 'function') {
      onClick(e);
    }
  };

  renderIcon () {
    const direction = this.props.direction;

    if (direction === 'up') {
      return <IconArrowUpSolid className={styles.icon} />;
    } else if (direction === 'down') {
      return <IconArrowDownLine className={styles.icon} />;
    } else {
      return null;
    }
  }

  get descriptionId () {
    return `${this.props.id}_desc`;
  }

  renderDescription () {
    if (this.props.description) {
      return (
        <ScreenReaderContent id={this.descriptionId}>
          {this.props.description}
        </ScreenReaderContent>
      );
    }
    return null;
  }

  render () {
    const {
      children,
      disabled,
      hidden,
      direction,
      zIndex,
    } = this.props;

    const classes = {
      [styles.root]: true,
      [styles['direction--' + direction]]: direction !== 'none'
    };

    const style = {
      zIndex: (zIndex) ? zIndex : null,
    };

    return (
      <span>
        <button
          type="button"
          onClick={this.handleClick}
          className={classnames(classes, styles.newActivityButton)}
          style={style}
          aria-disabled={(disabled) ? 'true' : null}
          aria-hidden={(hidden) ? 'true' : null}
          ref={this.props.buttonRef}
          aria-describedby={this.props.description ? this.descriptionId : null}
        >
          <span className={styles.layout}>
            {children}
            {this.renderIcon()}
          </span>
        </button>
        {this.renderDescription()}
      </span>
    );
  }
}

export default themeable(theme, styles)(StickyButton);
