/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!move_positions'

export function removeFromOrder (set, item) {
  const order = set.slice()
  const index = order.indexOf(item)
  if (index !== -1) {
    order.splice(index, 1)
  }
  return order
}

export const positions = {
  first: {
    type: 'absolute',
    label: I18n.t('First'),
    apply: ({ item, order }) => [item, ...removeFromOrder(order, item)],
  },
  before: {
    type: 'relative',
    label: I18n.t('Before..'),
    apply: ({ order, item, relativeTo }) => {
      const cleanedOrder = removeFromOrder(order, item)
      return [
        ...cleanedOrder.slice(0, relativeTo),
        item,
        ...cleanedOrder.slice(relativeTo),
      ]
    },
  },
  after: {
    type: 'relative',
    label: I18n.t('After..'),
    apply: ({ order, item, relativeTo }) => {
      const cleanedOrder = removeFromOrder(order, item)
      return [
        ...cleanedOrder.slice(0, relativeTo + 1),
        item,
        ...cleanedOrder.slice(relativeTo + 1),
      ]
    },
  },
  last: {
    type: 'absolute',
    label: I18n.t('Last'),
    apply: ({ order, item }) => [...removeFromOrder(order, item), item]
  },
}
