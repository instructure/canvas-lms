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

import {AnimatableRegistry} from '../animatable-registry';

function createAr () {
  const ar = new AnimatableRegistry();
  const days = [{day: 'zero'}, {day: 'one'}];
  const groups = [{group: 'zero'}, {group: 'one'}, {group: 'two'}, {group: 'three'}];
  const items = [
    {item: 'zero'}, {item: 'one'}, {item: 'two'}, {item: 'three'},
    {item: 'four'}, {item: 'five'}, {item: 'six'}, {item: 'seven'},
  ];
  const nais = [{nai: 'zero'}, {nai: 'one'}];
  ar.register('day', days[0], 0, ['1', '3', '5', '7']);
  ar.register('day', days[1], 1, ['0', '2', '4', '6']);
  ar.register('group', groups[0], 0, ['1', '3']);
  ar.register('group', groups[1], 1, ['5', '7']);
  ar.register('group', groups[2], 0, ['0', '2']);
  ar.register('group', groups[3], 1, ['4', '6']);
  ar.register('item', items[0], 0, ['0']);
  ar.register('item', items[1], 0, ['1']);
  ar.register('item', items[2], 1, ['2']);
  ar.register('item', items[3], 1, ['3']);
  ar.register('item', items[4], 0, ['4']);
  ar.register('item', items[5], 0, ['5']);
  ar.register('item', items[6], 1, ['6']);
  ar.register('item', items[7], 1, ['7']);
  ar.register('new-activity-indicator', nais[0], 1, ['5', '7']);
  ar.register('new-activity-indicator', nais[1], 1, ['4', '6']);
  return {ar, days, groups, items, nais};
}

it('borks on invalid types', () => {
  const {ar} = createAr();
  expect(() => ar.getComponent('bork', '42')).toThrow();
});

it('registers components', () => {
  const {ar, groups, items} = createAr();
  expect(ar.getComponent('group', '2').component).toBe(groups[2]);
  expect(ar.getComponent('group', '7').component).toBe(groups[1]);
  expect(ar.getFirstComponent('group', ['0', '2', '4', '6']).component).toBe(groups[2]);
  expect(ar.getLastComponent('group', ['1', '3', '5', '7']).component).toBe(groups[1]);
  expect(ar.getAllItemsSorted().map(item => item.component)).toEqual([
    items[1], items[3], items[5], items[7], items[0], items[2], items[4], items[6],
  ]);
});

it('overrides registrations', () => {
  const {ar} = createAr();
  const newGroup = {group: 'new'};
  ar.register('group', newGroup, 0, ['1', '3']);
  expect(ar.getComponent('group', '1').component).toBe(newGroup);
});

it('deregisters', () => {
  const {ar, groups} = createAr();
  ar.deregister('group', groups[0], ['1']);
  expect(ar.getComponent('group', '1')).not.toBeDefined();
  expect(ar.getComponent('group', '3').component).toBe(groups[0]);
});

it('only deregisters if component matches', () => {
  const {ar, groups} = createAr();
  ar.deregister('group', groups[1], ['1', '5']);
  expect(ar.getComponent('group', '1').component).toBe(groups[0]);
  expect(ar.getComponent('group', '5')).not.toBeDefined();
});

it('returns compacted list of new activity indicators', () => {
  const {ar, nais} = createAr();
  const result = ar.getAllNewActivityIndicatorsSorted();
  expect(result.map(r => r.component)).toEqual(nais);
});
