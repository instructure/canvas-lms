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
import formatMessage from '../format-message';
import {isTodayOrBefore} from './dateUtils';

const PILL_MAPPING = {
  'missing': () => ({ id: 'missing', text: formatMessage('Missing'), variant: 'danger' }),
  'late': () => ({ id: 'late', text: formatMessage('Late'), variant: 'danger' }),
  'graded': () => ({ id: 'graded', text: formatMessage('Graded') }),
  'excused': () => ({ id: 'excused', text: formatMessage('Excused') }),
  'submitted': () => ({ id: 'submitted', text: formatMessage('Submitted') }),
  'new_grades': () => ({ id: 'new_grades', text: formatMessage('Graded') }),
  'new_feedback': () => ({ id: 'new_feedback', text: formatMessage('Feedback') }),
  'new_replies': () => ({ id: 'new_replies', text: formatMessage('Replies') }),
};

export function isNewActivityItem (item) {
  return item.newActivity;
}

export function anyNewActivity (items) {
  return items && items.some(isNewActivityItem);
}

export function anyNewActivityDays (days) {
  return days.some(day => anyNewActivity(day[1]));
}

export function didWeFindToday (days) {
  return days.some(day => isTodayOrBefore(day[0]));
}

export function showPillForOverdueStatus(status, item) {
  if (!['late', 'missing'].includes(status)) {
    throw new Error(`Expected status to be 'late' or 'missing', but it was ${status}`);
  } else if (!item.status || !item.status[status] || !item.context) {
    return false;
  }

  return item.context.inform_students_of_overdue_submissions;
}

/**
* Returns an array of pill objects that the particular item
* qualifies to have
*/
export function getBadgesForItem (item) {
  let badges = [];
  if (item.status) {
    badges = Object.keys(item.status)
      .filter((key, index, all) => item.status.graded && key === 'submitted' ? false : true) // if graded, ignore submitted
      .filter((key) => {
        const validKeyPresent = item.status[key] && PILL_MAPPING.hasOwnProperty(key);

        if (!validKeyPresent) {
          return false;
        } else if (['late', 'missing'].includes(key)) {
          return showPillForOverdueStatus(key, item);
        }

        return true;
      })
      .map(a => PILL_MAPPING[a]());

    if (item.status.unread_count) {
      badges.push(PILL_MAPPING.new_replies());
    }
    if (item.newActivity && item.status.has_feedback) {
      badges.push(PILL_MAPPING.new_feedback());
    }
  }

  return badges;
}

/**
* Returns an array of pill objects that the items qualify to have
*/
export function getBadgesForItems (items) {
  const badges = [];
  if (items.some(i => i.status && i.newActivity && i.status.graded)) {
    badges.push(PILL_MAPPING.new_grades());
  }
  if (items.some(showPillForOverdueStatus.bind(this, 'missing'))) {
    badges.push(PILL_MAPPING.missing());
  } else if (items.some(showPillForOverdueStatus.bind(this, 'late'))) {
    badges.push(PILL_MAPPING.late());
  }
  if (items.some(i => i.status && i.newActivity && i.status.has_feedback)) {
    badges.push(PILL_MAPPING.new_feedback());
  }
  if (items.some(i => i.status && i.status.unread_count)) {
    badges.push(PILL_MAPPING.new_replies());
  }
  return badges;
}
