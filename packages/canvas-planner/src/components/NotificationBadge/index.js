/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import themeable from '@instructure/ui-themeable/lib';
import MissingIndicator from './MissingIndicator';
import NewActivityIndicator from './NewActivityIndicator';
import styles from './styles.css';
import theme from './theme.js';

class NotificationBadge extends React.Component {
  static propTypes = {
    children: PropTypes.element
  };

  render () {
    const indicator = this.props.children ? React.Children.only(this.props.children) : null;

    const activityIndicatorClasses = {
      [styles.activityIndicator]: true,
      [styles.hasBadge]: indicator != null
    };

    return (
      <div className={classnames(activityIndicatorClasses)}>
        {indicator}
      </div>
    );
  }
}
const ThemeableNotificationBadge = themeable(theme, styles)(NotificationBadge);

export {
  MissingIndicator,
  NewActivityIndicator,
  NotificationBadge,
};
export default ThemeableNotificationBadge;
