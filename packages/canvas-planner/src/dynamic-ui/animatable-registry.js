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
      opportunity: {},
      'new-activity-indicator': {},
    };
  }

  validateType (type) {
    const registryTypes = Object.keys(this.registries);
    if (!registryTypes.find((t) => t === type)) {
      throw new Error(`invalid registry type ${type}`);
    }
  }

  register (type, component, index, componentIds) {
    this.validateType(type);
    const registry = this.registries[type];
    componentIds.forEach(componentId => registry[componentId] = {component, index, componentIds});
  }

  deregister (type, component, componentIds) {
    this.validateType(type);
    const registry = this.registries[type];
    componentIds.forEach(componentId => {
      if (registry[componentId].component === component) {
        delete registry[componentId];
      }
    });
  }

  getComponent (type, componentId) {
    this.validateType(type);
    return this.registries[type][componentId];
  }

  getFirstComponent (type, componentIds) {
    this.validateType(type);
    const registry = this.registries[type];
    const minItemId = _.minBy(componentIds, componentId => registry[componentId].index);
    return registry[minItemId];
  }

  getLastComponent (type, componentIds) {
    this.validateType(type);
    const registry = this.registries[type];
    const maxItemId = _.maxBy(componentIds, componentId => registry[componentId].index);
    return registry[maxItemId];
  }

  getUniqSortedComponents (type, componentIds) {
    this.validateType(type);
    let components = componentIds.map(componentId => this.registries[type][componentId]);
    return _.chain(components).sortBy('index').sortedUniqBy('index').value();
  }

  // Gets all non-negative indexed components from the given registry in indexed order. Negative
  // indexed components are special and are not returned by this method. This method only makes
  // sense for days and opportunities since groups and items are nested components and will have
  // duplicate indexes registered (with different ids).
  getSortedComponents (type) {
    this.validateType(type);
    return _.chain(this.registries[type])
      .values()
      .sortBy('index')
      .sortedUniqBy('index')
      .filter(entryValue => entryValue.index >= 0)
      .value();
  }

  getAllGroupsSorted () {
    // get list of days sorted as they appear in the interface.
    const sortedDays = this.getSortedComponents('day');
    // get sorted groups for each sorted day, then flatten into one list of interface sorted groups.
    const sortedGroups = _.flatMap(sortedDays, day => this.getUniqSortedComponents('group', day.componentIds));
    return sortedGroups;
  }

  // gets all items that are displayed in the interface in interface sorted order.
  getAllItemsSorted () {
    const sortedGroups = this.getAllGroupsSorted();
    // get sorted items for each group, then flatten into one list of interface sorted items
    const sortedItems = _.flatMap(sortedGroups, group => this.getUniqSortedComponents('item', group.componentIds));
    return sortedItems;
  }

  // gets indexed opportunities in interface order.
  getAllOpportunitiesSorted () {
    return this.getSortedComponents('opportunity');
  }

  getAllNewActivityIndicatorsSorted () {
    const sortedGroups = this.getAllGroupsSorted();
    const sortedNewActivityIndicators = _.chain(sortedGroups)
      .flatMap(group => this.getUniqSortedComponents('new-activity-indicator', group.componentIds))
      // not every group has a new activity indicator, so remove the undefined components
      .filter(nai => nai != null)
      .value();
    return sortedNewActivityIndicators;
  }
}
