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
import { momentObj } from 'react-moment-proptypes';
import themeable from '@instructure/ui-themeable/lib';
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails';
import Pill from '@instructure/ui-elements/lib/components/Pill';
import BadgeList from '../BadgeList';
import NotificationBadge, { MissingIndicator, NewActivityIndicator} from '../NotificationBadge';
import { func, number, string, arrayOf, shape, oneOf } from 'prop-types';
import { badgeShape, sizeShape } from '../plannerPropTypes';
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
    notificationBadge: oneOf(['none', 'newActivity', 'missing']),
    date: momentObj,  // the scroll-to-today animation requires a date on each component in the planner
    responsiveSize: sizeShape,
  };
  static defaultProps = {
    badges: [],
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    notificationBadge: 'none',
    responsiveSize: 'large',
  };

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

  getFocusable = () => { return this.buttonRef; }

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

  renderNotificationBadge () {
    if (this.props.notificationBadge === 'none') return <NotificationBadge responsiveSize={this.props.responsiveSize} />;

    const isNewItem = this.props.notificationBadge === 'newActivity';
    const IndicatorComponent = isNewItem ? NewActivityIndicator : MissingIndicator;
    const badgeMessage = formatMessage('{items} completed {items, plural,=1 {item} other {items}}', {items: this.props.itemCount});
    return (
      <NotificationBadge responsiveSize={this.props.responsiveSize}>
      <div className={styles.activityIndicator}>
        <IndicatorComponent
        title={badgeMessage}
        itemIds={this.props.animatableItemIds}
        animatableIndex={this.props.animatableIndex}
        getFocusable={this.getFocusable} />
      </div>
      </NotificationBadge>
    );
  }
  render () {
    const theme = this.theme ? {
      textColor: this.theme.labelColor,
      iconColor: this.theme.labelColor,
      iconMargin: this.theme.gutterWidth,
    } : null;
    return (
      <div
        className={classnames(styles.root, styles[this.props.responsiveSize], 'planner-completed-items')}
        ref={elt => this.rootDiv = elt}
      >
        {this.renderNotificationBadge()}
        <div className={styles.contentPrimary}>
          <ToggleDetails
            ref={ref => this.buttonRef = ref}
            onToggle={this.props.onClick}
            summary={formatMessage(`{
                  count, plural,
                  one {Show # completed item}
                  other {Show # completed items}
                }`, { count: this.props.itemCount })}
            theme={theme}
          >
            ToggleDetails requires a child
          </ToggleDetails>
        </div>
        <div className={styles.contentSecondary}>
          {this.renderBadges()}
        </div>
      </div>
    );
  }
}

export default animatable(themeable(theme, styles)(CompletedItemsFacade));
