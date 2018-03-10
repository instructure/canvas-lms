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
import {
  anyNewActivity,
  getBadgesForItem,
  getBadgesForItems,
  showPillForOverdueStatus
} from '../statusUtils';

describe('getBadgesForItem', () => {
  it('returns an empty array when there is not activity or status', () => {
    expect(getBadgesForItem({})).toHaveLength(0);
  });

  it('returns missing status with a danger variant and "Missing" text', () => {
    const item = { status: { missing: true }, context: { inform_students_of_overdue_submissions: true } };
    expect(getBadgesForItem(item)).toEqual([{
      id: 'missing',
      text: 'Missing',
      variant: 'danger'
    }]);
  });

  it('does not return a "Missing" badge if the course is set to not inform students of overdue submissions', () => {
    const item = { status: { missing: true }, context: { inform_students_of_overdue_submissions: false } };
    expect(getBadgesForItem(item)).toEqual([]);
  });

  it('returns late status with a danger variant and "Late" text', () => {
    const item = { status: { late: true }, context: { inform_students_of_overdue_submissions: true } };
    expect(getBadgesForItem(item)).toEqual([{
      id: 'late',
      text: 'Late',
      variant: 'danger'
    }]);
  });

  it('does not return a "Late" badge if the course is set to not inform students of overdue submissions', () => {
    const item = { status: { late: true }, context: { inform_students_of_overdue_submissions: false } };
    expect(getBadgesForItem(item)).toEqual([]);
  });

  it('returns new_replies status when there is an unread_count', () => {
    const item = { status: { unread_count: 42 }};
    expect(getBadgesForItem(item)).toEqual([{
      id: 'new_replies', text: 'Replies',
    }]);
  });

  it('does not set new_replies when unread_count is 0', () => {
    const item = { status: { unread_count: 0 }};
    expect(getBadgesForItem(item)).toEqual([]);
  });

  it('does not barf on unrecognized statuses', () => {
    const item = { status: { barf: true }};
    expect(getBadgesForItem(item)).toEqual([]);
  });
});

describe('getBadgesForItems', () => {
  it('returns an empty array if nothing matches', () => {
    expect(getBadgesForItems([{ status: 'excused' }, { status: 'late' }])).toEqual([]);
  });

  it('returns New Grades object when at least one new activity item has a graded status', () => {
    const items = [{ newActivity: true, status: { graded: true } }, { status: { excused: true } }];
    expect(getBadgesForItems(items)).toContainEqual({
      id: 'new_grades',
      text: 'Graded'
    });
  });

  it('returns New Feedback object when at least one new activity item has a has_feedback status', () => {
    const items = [{ status: { fake: true } }, { newActivity: true, status: { has_feedback: true } }];
    expect(getBadgesForItems(items)).toContainEqual({
      id: 'new_feedback',
      text: 'Feedback'
    });
  });

  it('returns Missing object when at least one new activity item has a missing status', () => {
    const items = [
      { status: { fake: true }, context: { inform_students_of_overdue_submissions: true } },
      { newActivity: true, status: { missing: true }, context: { inform_students_of_overdue_submissions: true } }
    ];
    expect(getBadgesForItems(items)).toContainEqual({
      id: 'missing',
      text: 'Missing',
      variant: 'danger'
    });
  });

  it('does not return a "Missing" badge when the course is set to not inform students of overdue submissions', () => {
    const items = [
      { status: { fake: true }, context: { inform_students_of_overdue_submissions: true } },
      { newActivity: true, status: { missing: true }, context: { inform_students_of_overdue_submissions: false } }
    ];
    expect(getBadgesForItems(items)).toEqual([]);
  });

  it('returns Late object when at least one new activity item has a missing status', () => {
    const items = [
      { status: { fake: true }, context: { inform_students_of_overdue_submissions: true } },
      { newActivity: true, status: { late: true }, context: { inform_students_of_overdue_submissions: true } }
    ];
    expect(getBadgesForItems(items)).toContainEqual({
      id: 'late',
      text: 'Late',
      variant: 'danger'
    });
  });

  it('does not return a "Late" badge when the course is set to not inform students of overdue submissions', () => {
    const items = [
      { status: { fake: true }, context: { inform_students_of_overdue_submissions: true } },
      { newActivity: true, status: { late: true }, context: { inform_students_of_overdue_submissions: false } }
    ];
    expect(getBadgesForItems(items)).toEqual([]);
  });

  // 'late' and 'missing' are mutually exclusive, so this case should not possible, but
  // if things change down the road and 'late' and 'missing' can both be true, we
  // will show the 'missing' badge only.
  it('returns Missing object when an item is both missing and late', () => {
    const items = [
      {
        status: { fake: true },
        context: { inform_students_of_overdue_submissions: true }
      },
      {
        newActivity: true,
        status: { missing: true, late: true },
        context: { inform_students_of_overdue_submissions: true }
      }
    ];
    expect(getBadgesForItems(items)).toEqual([{
      id: 'missing',
      text: 'Missing',
      variant: 'danger'
    }]);
  });

  it('does not return New Grades object when only old items have a graded status', () => {
    const items = [{ status: { graded: true } }, { status: { excused: true } }];
    expect(getBadgesForItems(items)).toEqual([]);
  });

  it('does not return New Feedback object when only old items have a has_feedback status', () => {
    const items = [{ status: { fake: true } }, { status: { has_feedback: true } }];
    expect(getBadgesForItems(items)).toEqual([]);
  });

  it('returns New Replies object when at least one item has a non-zero unread count', () => {
    const items = [{ status: { unread_count: 0 } }, { status: { unread_count: 3 } }];
    expect(getBadgesForItems(items)).toContainEqual({
      id: 'new_replies',
      text: 'Replies'
    });
  });
});

describe('new activity', () => {
  it('detects items for new activity', () => {
    const items = [ {newActivity: false}, {newActivity: true} ];
    expect(anyNewActivity(items)).toBeTruthy();
  });

  it('does not detect items when no new activity', () => {
    const items = [ {newActivity: false}, {newActivity: false} ];
    expect(anyNewActivity(items)).toBeFalsy();
  });
});

describe('showPillForOverdueStatus', () => {
  let item;

  beforeEach(() => {
    item = {
      status: { missing: true, late: false },
      context: { inform_students_of_overdue_submissions: true }
    };
  });

  it('throws an error if the status is not "late" or "missing"', () => {
    expect(showPillForOverdueStatus.bind(this, 'wat', item)).toThrow();
  });

  it(`returns true if the value is true for the requested status and the
    course is set to inform students of overdue submissions`, () => {
    expect(showPillForOverdueStatus('missing', item)).toEqual(true);
  });

  it(`returns false if the value is true for the requested status but the
    course is set to not inform students of overdue submissions`, () => {
    item.context.inform_students_of_overdue_submissions = false;
    expect(showPillForOverdueStatus('missing', item)).toEqual(false);
  });

  it('returns false if the "status" on the item is null', () => {
    item.status = null;
    expect(showPillForOverdueStatus('missing', item)).toEqual(false);
  });

  it('returns false if the value is not true for the requested status', () => {
    item.status.missing = false;
    expect(showPillForOverdueStatus('missing', item)).toEqual(false);
  });

  it('returns false if the "context" on the item is null', () => {
    item.context = null;
    expect(showPillForOverdueStatus('missing', item)).toEqual(false);
  });
});
