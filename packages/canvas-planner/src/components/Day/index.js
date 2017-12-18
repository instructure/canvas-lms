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
import moment from 'moment-timezone';
import themeable from '@instructure/ui-themeable/lib';
import Heading from '@instructure/ui-core/lib/components/Heading';
import Text from '@instructure/ui-core/lib/components/Text';
import Container from '@instructure/ui-core/lib/components/Container';
import { shape, string, number, arrayOf, func, bool } from 'prop-types';
import styles from './styles.css';
import theme from './theme.js';
import { getFriendlyDate, getFullDate, isToday } from '../../utilities/dateUtils';
import { groupBy } from 'lodash';
import Grouping from '../Grouping';
import formatMessage from '../../format-message';
import { animatable } from '../../dynamic-ui';

export class Day extends Component {
  static propTypes = {
    day: string.isRequired,
    itemsForDay: arrayOf(shape({
      context: shape({
        inform_students_of_overdue_submissions: bool.isRequired
      })
    })),
    animatableIndex: number,
    timeZone: string.isRequired,
    toggleCompletion: func,
    updateTodo: func,
    alwaysRender: bool,
    registerAnimatable: func,
    deregisterAnimatable: func,
  }

  constructor (props) {
    super(props);

    const tzMomentizedDate = moment.tz(props.day, props.timeZone);
    this.friendlyName = getFriendlyDate(tzMomentizedDate);
    this.fullDate = getFullDate(tzMomentizedDate);
    this.state = {
      groupedItems: this.groupItems(props.itemsForDay)
    };
  }

  componentDidMount () {
    this.props.registerAnimatable('day', this, this.props.animatableIndex, this.itemUniqueIds());
  }

  componentWillReceiveProps (nextProps) {
    this.props.deregisterAnimatable('day', this, this.itemUniqueIds());
    this.props.registerAnimatable('day', this, nextProps.animatableIndex, this.itemUniqueIds(nextProps));

    this.setState((state) => {
      return {
        groupedItems: this.groupItems(nextProps.itemsForDay)
      };
    });
  }

  componentWillUnmount () {
    this.props.deregisterAnimatable('day', this, this.itemUniqueIds());
  }

  itemUniqueIds (props = this.props) { return props.itemsForDay.map(item => item.uniqueId); }

  groupItems = (items) => groupBy(items, item => (item.context && (item.context.type+item.context.id)) || 'Notes');

  hasItems () {
    return !!Object.keys(this.state.groupedItems).length;
  }

  shouldRender () {
    if (this.props.alwaysRender) return true;
    const myDate = moment.tz(this.props.day, this.props.timeZone);
    const today = moment.tz(this.props.timeZone);
    const future = today.clone().add(2, 'weeks');
    const past = today.clone().subtract(2, 'weeks');
    if (myDate.isBetween(past, future, 'days')) return true;
    return this.hasItems();
  }

  render () {
    if (!this.shouldRender()) return null;

    return (
      <div className={styles.root} >
          <Heading
            border={(this.hasItems()) ? 'none' : 'bottom'}
          >
            <Text
              as="div"
              transform="uppercase"
              lineHeight="condensed"
              size={isToday(this.props.day) ? 'large' : 'medium'}
            >
              {this.friendlyName}
            </Text>
            <Text
              as="div"
              lineHeight="condensed"
            >
              {this.fullDate}
            </Text>
          </Heading>

        <div>
          {
            (this.hasItems()) ? (
              Object.keys(this.state.groupedItems).map((cid, groupIndex) => {
                const groupItems = this.state.groupedItems[cid];
                const courseInfo = groupItems[0].context || {};
                return (
                  <Grouping
                    title={courseInfo.title}
                    image_url={courseInfo.image_url}
                    color={courseInfo.color}
                    timeZone={this.props.timeZone}
                    updateTodo={this.props.updateTodo}
                    items={groupItems}
                    animatableIndex={groupIndex}
                    url={courseInfo.url}
                    key={cid}
                    theme={{
                      titleColor: courseInfo.color || null
                    }}
                    toggleCompletion={this.props.toggleCompletion}
                  />
                );
              })
            ) : (
              <Container
                textAlign="center"
                display="block"
                margin="small 0 0 0"
              >
                {formatMessage('No "To-Do\'s" for this day yet.')}
              </Container>
            )
          }
        </div>
      </div>
    );
  }
}

export default animatable(themeable(theme, styles)(Day));
