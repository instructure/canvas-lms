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

import React from 'react'
import ReactDOM from 'react-dom'

import MoveItemTray from './react/index'

const ROOT_ID = 'move_item_tray'

export function renderTray(props, rootContainer = document.body) {
  let root = document.getElementById(ROOT_ID)

  if (!root) {
    root = document.createElement('div')
    root.setAttribute('id', ROOT_ID)
    rootContainer.appendChild(root)
  }

  ReactDOM.render(<MoveItemTray {...props} ref={tray => tray && tray.open()} />, root)
}

export const backbone = {
  collectionToItems(collection, getItems = col => col.models) {
    return getItems(collection).map(item => ({
      id: item.attributes.id,
      title: item.attributes.name || item.attributes.title,
    }))
  },

  collectionToGroups(collection, getItems, filter = () => true) {
    return collection.models.filter(filter).map(item => ({
      id: item.attributes.id,
      title: item.attributes.name || item.attributes.title,
      items: this.collectionToItems(getItems(item)),
    }))
  },

  reorderInCollection(order, model, collection = model.collection) {
    order.forEach((id, index) => {
      const item = collection.get(id)
      if (item) item.set('position', index + 1)
    })

    // call reset to trigger a re-render
    collection.sort()
    collection.reset(collection.models)
  },

  reorderAcrossCollections(order, collId, model, keys) {
    let newColl = model.collection.view.parentCollection.get(collId).get(keys.model)

    // if item moved across collections
    if (newColl && newColl !== model.collection) {
      model.collection.remove(model)
      newColl.add(model)

      if (keys.parent) {
        model.set(keys.parent, collId)
      }
    } else {
      newColl = model.collection
    }

    this.reorderInCollection(order, model, newColl)
  },

  reorderAllItemsIntoNewCollection(order, collId, model, keys) {
    let newColl = model.collection.get(collId).get(keys.model)
    // if item moved across collections
    if (newColl && newColl !== model.collection) {
      const allAssignments = model.get(keys.model).models.slice()

      allAssignments.forEach(asg => {
        model.get(keys.model).remove(asg)
        newColl.add(asg)
      })

      if (keys.parent) {
        model.set(keys.parent, collId)
      }
    } else {
      newColl = model.collection
    }

    this.reorderInCollection(order, model, newColl)
  },
}

export function reorderElements(order, container, idToItemSelector = id => `#${id}`) {
  const itemMap = order.reduce((items, id) => {
    const item = container.querySelector(idToItemSelector(id))
    if (item == null) return items
    items[id] = item
    container.removeChild(item)
    return items
  }, {})

  order.forEach(id => {
    if (itemMap[id] != null) container.appendChild(itemMap[id])
  })
}
