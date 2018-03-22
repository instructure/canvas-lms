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
import themeable from '@instructure/ui-themeable/lib';
import containerQuery from '@instructure/ui-utils/lib/react/containerQuery';
import Button from '@instructure/ui-core/lib/components/Button';
import Pill from '@instructure/ui-core/lib/components/Pill';
import IconArrowOpenRight from 'instructure-icons/lib/Solid/IconArrowOpenRightSolid';
import BadgeList from '../BadgeList';
import { func, number, string, arrayOf, shape } from 'prop-types';
import { badgeShape } from '../plannerPropTypes';
import {animatable} from '../../dynamic-ui';

import styles from './styles.css';
import theme from './theme.js';

import formatMessage from '../../format-message';

export class CompletedItemsFacade extends Component {

  static propTypes = {
    onClick: func.isRequired,
    itemCount: number.isRequired,
    badges: arrayOf(shape(badgeShape)),
    animatableIndex: number,
    animatableItemIds: arrayOf(string),
    registerAnimatable: func,
    deregisterAnimatable: func,
  }

  static defaultProps = {
    badges: [],
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
  }

  componentDidMount () {
    this.props.registerAnimatable('item', this, this.props.animatableIndex, this.props.animatableItemIds);
  }

  componentWillReceiveProps (newProps) {
    this.props.deregisterAnimatable('item', this, this.props.animatableItemIds);
    this.props.registerAnimatable('item', this, newProps.animatableIndex, newProps.animatableItemIds);
  }

  componentWillUnmount () {
    this.props.deregisterAnimatable('item', this, this.props.animatableItemIds);
  }

  getFocusable () { return this.buttonRef; }

  getScrollable () { return this.rootDiv; }

  renderBadges () {
    if (this.props.badges.length) {
      return (
        <BadgeList>
          {
            this.props.badges.map((b) => (
              <Pill
                key={b.id}
                text={b.text}
                variant={b.variant} />
            ))
          }
        </BadgeList>
      );
    }
    return null;
  }

  render () {
    return (
      <div className={styles.root} ref={elt => this.rootDiv = elt}>
        <div className={styles.contentPrimary}>
          <Button
            variant="link"
            ref={ref => this.buttonRef = ref}
            onClick={this.props.onClick}
          >
            <IconArrowOpenRight/>
            <span className={styles.showLabel}>
              {
                formatMessage(`{
                  count, plural,
                  one {Show # completed item}
                  other {Show # completed items}
                }`, { count: this.props.itemCount })
              }
            </span>
          </Button>

        </div>
        <div className={styles.contentSecondary}>
          {this.renderBadges()}
        </div>
      </div>
    );
  }
}

export default animatable(themeable(theme, styles)(
  // we can update this to be whatever works for this component and its content
  containerQuery({
    'media-x-large': { minWidth: '68rem' },
    'media-large': { minWidth: '58rem' },
    'media-medium': { minWidth: '34rem' }
  })(CompletedItemsFacade)
));
