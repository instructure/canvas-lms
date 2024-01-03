/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import {isArray, difference} from 'lodash'

extend(UniqueDropdownCollection, Backbone.Collection)

// For all your dropdown widget-y needs.
//
// Example: Say I have a list of sections I want to assign for some due dates.
// I have an example UI that has several <select> dropdowns that looks like:
//
// <select name="section_id"><!-- options go here... ></select>
// <input type=date name="due_date"/>
//
// Imagine you have 4 sections in the course, so you'd have 4 widgets
// with the above markup.
//
// However, say you have a unique constraint that a section may only have one
// due date. To help the user's experience, we want to hide sections that
// have already been assigned a due date in the other drop downs. We also
// want to make the interface very responsive, so adding changing the section
// in one dropdown makes the section available to choose in all the other
// dropdowns (since it was previously taken, but now available to choose from).
// You can use the variable due date widget to see an example of this behavior.
// (NOTE: The variable due date widget doesn't use this... yet)
//
// UniqueDropdownCollection will watch your models for change events, so
// when your passed 'propertyName' value changes, UniqueDropdownCollection
// will remove it from `collection.takenValues` and add it to
// `collection.availableValues` accordingly. `availableValues` and
// `takenValues` are both instances of `Backbone.Collection`, so you
// can use the handy dandy `change/add/remove` events we all love. See
// the documentation below for what kind of objects these collections
// store the possible values as.
//
// You can also call `add/remove` like you would on a normal
// `Backbone.Collection`. UniqueDropdownCollection will make a value
// available if you remove the record, and taken if you create a new record
// (the new record will have the first available value in `availableValues`.
//
// Example:
//
// ENV.SECTION_IDS = [1, 2, 3, 4]
// models = (new Assignment(id: i, section_id: i) for i in [1..3])
//
// collection = new UniqueDropdownCollection models,
//   model: Assignment
//   propertyName: 'section_id'
//   possibleValues: ENV.SECTION_IDS
//
// collection.availableValues.find (m) -> m.get('value') == 4 # true
// collection.takenValues.find (m) -> m.get('value') == 4 # false
//
// models[0].set 'section_id', 4
//
// collection.availableValues.find (m) -> m.get('value') == 4 # false
// collection.takenValues.find (m) -> m.get('value') == 4 # true
//
// Listening for changes on `availableValues` and `takenValues`
//
// These collections have objects that look like this:
//
//   id: 'some value goes here'
//   value: 'some value goes here'
//
// If you're going to listen on these collections, I recommend listening on
// the `add/remove` events of the collections, and re-render your dropdown
// accordingly.

function UniqueDropdownCollection() {
  this.removeModel = this.removeModel.bind(this)
  this.updateAvailableValues = this.updateAvailableValues.bind(this)
  this.calculateTakenValues = this.calculateTakenValues.bind(this)
  return UniqueDropdownCollection.__super__.constructor.apply(this, arguments)
}

// Public
//   records - Array of records to watch for changes on
//   options: a hash with the usual options Backbone.Collection takes, with
//   a few extra added goodies:
//     propertyName: string representing the property name on your model.
//       e.g. model.get('section_id')
//     possibleValues: an array of possible values `propertyName` can
//       choose from
//
//   NOTE: BE SURE TO PASS A `model` OPTION!
UniqueDropdownCollection.prototype.initialize = function (records, options) {
  if (options == null) {
    options = {}
  }
  // we need to reset the collections so that
  // we can calculate the fresh taken and available values
  // @takenValues.reset null, silent: true
  // @availableValues.reset null, silent: true
  // Create Backbone Models with IDs so we can remove and add them
  // quickly (rather than filtering and removing from an index every time)
  // in @takenValues and @availableValues
  this.takenValues || (this.takenValues = new Backbone.Collection([]))
  this.availableValues || (this.availableValues = new Backbone.Collection([]))
  this.possibleValues = options.possibleValues
  this.propertyName = options.propertyName
  this.availableValues.comparator = 'value'
  this.calculateTakenValues(records)
  this.on('reset', this.calculateTakenValues)
  this.on('change:' + this.propertyName, this.updateAvailableValues)
  return this.on('remove', this.removeModel)
}

UniqueDropdownCollection.prototype.calculateTakenValues = function (records) {
  let i, j, len, len1, model, takenValue, takenValues, value
  if (records instanceof Backbone.Collection) {
    takenValues = records.map(
      (function (_this) {
        return function (m) {
          return m.get(_this.propertyName)
        }
      })(this)
    )
  } else {
    takenValues = function () {
      const results_ = []
      for (let i_ = 0, len_ = records.length; i_ < len_; i_++) {
        model = records[i_]
        results_.push(model.get(this.propertyName))
      }
      return results_
    }.call(this)
  }
  this.takenValues.reset(null, {
    silent: true,
  })
  this.availableValues.reset(null, {
    silent: true,
  })
  for (i = 0, len = takenValues.length; i < len; i++) {
    takenValue = takenValues[i]
    this.takenValues.add(
      new Backbone.Model({
        id: takenValue,
        value: takenValue,
      })
    )
  }
  const ref = difference(this.possibleValues, takenValues)
  const results = []
  for (j = 0, len1 = ref.length; j < len1; j++) {
    value = ref[j]
    results.push(
      this.availableValues.add(
        new Backbone.Model({
          id: value,
          value,
        })
      )
    )
  }
  return results
}

UniqueDropdownCollection.prototype.updateAvailableValues = function (model) {
  const previousValue = model.previousAttributes()[this.propertyName]
  const currentValue = model.get(this.propertyName)
  const previouslyAvailableValue = this.availableValues.get(currentValue)
  const previouslyTakenValue = this.takenValues.get(previousValue)
  this.availableValues.remove(previouslyAvailableValue)
  this.takenValues.remove(previouslyTakenValue)
  this.takenValues.add(previouslyAvailableValue)
  return this.availableValues.add(previouslyTakenValue)
}

UniqueDropdownCollection.prototype.removeModel = function (model) {
  const value = model.get(this.propertyName)
  const previouslyTakenValue = this.takenValues.get(value)
  this.takenValues.remove(previouslyTakenValue)
  return this.availableValues.add(previouslyTakenValue)
}

// method for how to find the next model to add.
// defaults to the first item
// in @availableValues
//
// override if you need more complex logic
//
// Returns a model from @availableValues
UniqueDropdownCollection.prototype.findNextAvailable = function () {
  return this.availableValues.at(0)
}

UniqueDropdownCollection.prototype.add = function (models, _options) {
  if (!isArray(models) && typeof models === 'object' && !(models instanceof Backbone.Model)) {
    const previouslyAvailableValue = this.findNextAvailable()
    this.availableValues.remove(previouslyAvailableValue)
    this.takenValues.add(previouslyAvailableValue)
    models[this.propertyName] = previouslyAvailableValue.get('value')
  }
  return UniqueDropdownCollection.__super__.add.apply(this, arguments)
}

export default UniqueDropdownCollection
