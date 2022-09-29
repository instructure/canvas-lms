/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

// Handles navigation through a collection.
import Backbone from '@canvas/backbone'

export default {
  isBackboneCollection(collection) {
    return collection instanceof Backbone.Collection
  },

  // Get the previous item in a collection.
  getPreviousInRelationTo(collection, collectionItem) {
    const isBackbone = this.isBackboneCollection(collection)

    const itemIndex = collection.indexOf(collectionItem)

    // Return null if the item wasn't found.
    if (!(itemIndex >= 0)) {
      return null
    }

    const nextIndex = itemIndex - 1

    // Return the last item if we were at the first.
    if (nextIndex < 0) {
      if (isBackbone) {
        return collection.at(collection.length - 1)
      } else {
        return collection[collection.length - 1]
      }
    }

    // Otherwise let's just return the previous item.
    if (isBackbone) {
      return collection.at(nextIndex)
    } else {
      return collection[nextIndex]
    }
  },

  // Get the next item in a collection.
  getNextInRelationTo(collection, collectionItem) {
    const isBackbone = this.isBackboneCollection(collection)

    const itemIndex = collection.indexOf(collectionItem)

    // Return null if the item wasn't found.
    if (!(itemIndex >= 0)) return null

    const nextIndex = itemIndex + 1

    // Return the first item if we were at the last.
    if (nextIndex > collection.length - 1) {
      if (isBackbone) {
        return collection.at(0)
      } else {
        return collection[0]
      }
    }
    // Otherwise let's just return the next item.
    if (isBackbone) {
      return collection.at(nextIndex)
    } else {
      return collection[nextIndex]
    }
  },
}
