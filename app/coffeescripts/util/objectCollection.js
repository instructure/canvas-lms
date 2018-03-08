//
// Copyright (C) 2011 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// Utility methods for arrays of objects
//
// Returns an array with extra methods.  It uses direct property injection so our
// prototypes are still clean, but we get a nice OO syntax for these kinds
// of arrays.

export default function objectCollectionMixin(array) {
  array.indexOf = needle => {
    for (let index = 0; index < array.length; index++) {
      const item = array[index]
      if (item === needle) {
        return index
      }
    }
    return -1
  }

  // Can find a specific element by a property ie:
  //   arr = arrayOfObjects([{id: 1}, {id: 2}])
  //   arr.findBy('id', 1) //> {id: 1}
  array.findBy = (prop, value) => {
    for (let index = 0; index < array.length; index++) {
      const item = array[index]
      if (item[prop] === value) {
        return item
      }
    }
    return false
  }

  array.eraseBy = (prop, value) => {
    const item = array.findBy(prop, value)
    return array.erase(item)
  }

  // Inserts an item into an array at a specific index
  array.insert = (item, index = 0) => array.splice(index, 0, item)

  // erases an item from an array, if it exists
  array.erase = victim => {
    for (let index = 0; index < array.length; index++) {
      const prospect = array[index]
      if (prospect === victim) {
        array.splice(index, 1)
      }
    }
  }

  const sorters = {
    string(a, b) {
      if (a < b) {
        return -1
      } else if (a > b) {
        return 1
      } else {
        return 0
      }
    },
    number(a, b) {
      return a - b
    }
  }

  // Sort an array of of objects by object property, Supports sorting by strings
  // and numbers
  array.sortBy = function(prop) {
    if (array.length === 0) return array
    const type = typeof array[0][prop] || 'string'
    return array.sort((a, b) => sorters[type](a[prop], b[prop]))
  }

  return array
}
