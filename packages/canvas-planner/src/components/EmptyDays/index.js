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


import React, { Component } from 'react';
import moment from 'moment-timezone';
import classnames from 'classnames';
import themeable from '@instructure/ui-themeable/lib';
import Heading from '@instructure/ui-elements/lib/components/Heading';
import Text from '@instructure/ui-elements/lib/components/Text';
import View from '@instructure/ui-layout/lib/components/View';
import { string } from 'prop-types';
import styles from './styles.css';
import theme from './theme.js';
import { getShortDate } from '../../utilities/dateUtils';
import formatMessage from '../../format-message';
import GroupedDates from './grouped_dates.svg';

export class EmptyDays extends Component {
  static propTypes = {
    day: string.isRequired,
    endday: string.isRequired,
    timeZone: string.isRequired,
  };

  renderDate (start, end) {
    let dateString;
    dateString = formatMessage('{startDate} to {endDate}',
      {
        startDate: getShortDate(start),
        endDate: getShortDate(end)
      });
    return (
      <Text as="div" lineHeight="condensed">
        {dateString}
      </Text>
    );
  }

  render () {
    const now = moment.tz(this.props.timeZone);
    const start = moment.tz(this.props.day, this.props.timeZone).startOf('day');
    const end = moment.tz(this.props.endday, this.props.timeZone).endOf('day');
    const includesToday = (now.isSame(start, 'day') || now.isAfter(start, 'day')) &&
                          (now.isSame(end, 'day')   || now.isBefore(end, 'day'));

    return (
      <div className={classnames(styles.root, 'planner-empty-days', {'planner-today': includesToday})} >
          <Heading border={'bottom'}>
            {this.renderDate(start, end)}
          </Heading>
          <View as="div" padding="small 0 0 0">
            <GroupedDates role="img" aria-hidden="true" />
            <div className={styles.nothingPlannedContainer}>
              <div className={styles.nothingPlanned}>
                <Text size="large">{formatMessage('Nothing Planned Yet')}</Text>
              </div>
            </div>
          </View>
      </div>
    );
  }
}

export default themeable(theme, styles)(EmptyDays);
