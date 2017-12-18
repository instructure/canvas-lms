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

import _ from 'lodash';

export class AnimatableRegistry {
  constructor () {
    this.registries = {
      day: {},
      group: {},
      item: {},
    };
  }

  validateType (type) {
    if (!['day', 'group', 'item'].find((t) => t === type)) {
      throw new Error(`invalid registry type ${type}`);
    }
  }

  register (type, component, index, itemIds) {
    this.validateType(type);
    const registry = this.registries[type];
    itemIds.forEach(itemId => registry[itemId] = {component, index, itemIds});
  }

  deregister (type, component, itemIds) {
    this.validateType(type);
    const registry = this.registries[type];
    itemIds.forEach(itemId => {
      if (registry[itemId].component === component) {
        delete registry[itemId];
      }
    });
  }

  getComponent (type, itemId) {
    this.validateType(type);
    return this.registries[type][itemId];
  }

  getFirstComponent (type, itemIds) {
    this.validateType(type);
    const registry = this.registries[type];
    const minItemId = _.minBy(itemIds, itemId => registry[itemId].index);
    return registry[minItemId];
  }

  getLastComponent (type, itemIds) {
    this.validateType(type);
    const registry = this.registries[type];
    const maxItemId = _.maxBy(itemIds, itemId => registry[itemId].index);
    return registry[maxItemId];
  }

  getUniqSortedComponents (type, itemIds) {
    this.validateType(type);
    let components = itemIds.map(itemId => this.registries[type][itemId]);
    return _.chain(components).sortBy('index').sortedUniqBy('index').value();
  }

  getAllItemsSorted () {
    const sortedDays = _.chain(this.registries.day).values().sortBy('index').sortedUniqBy('index').value();
    const sortedGroups = _.flatMap(sortedDays, day => this.getUniqSortedComponents('group', day.itemIds));
    const sortedItems = _.flatMap(sortedGroups, group => this.getUniqSortedComponents('item', group.itemIds));
    return sortedItems;
  }
}
