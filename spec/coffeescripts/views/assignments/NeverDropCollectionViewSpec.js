/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import Backbone from 'Backbone'
import NeverDropCollection from 'compiled/collections/NeverDropCollection'
import NeverDropCollectionView from 'compiled/views/assignments/NeverDropCollectionView'
import {useNormalDebounce, useOldDebounce} from 'helpers/util'

class AssignmentStub extends Backbone.Model {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) {
        super()
      }
      const thisFn = (() => {
        this
      }).toString()
      const thisName = thisFn.slice(thisFn.indexOf('{') + 1, thisFn.indexOf(';')).trim()
      eval(`${thisName} = this;`)
    }
    this.toView = this.toView.bind(this)
    super(...args)
  }

  name() {
    return this.get('name')
  }
  toView() {
    return {
      name: this.get('name'),
      id: this.id
    }
  }
}

class Assignments extends Backbone.Collection {
  static initClass() {
    this.prototype.model = AssignmentStub
  }
}
Assignments.initClass()

QUnit.module('NeverDropCollectionView', {
  setup() {
    this.clock = sinon.useFakeTimers()
    useOldDebounce()
    this.assignments = new Assignments([1, 2, 3].map(i => ({id: `${i}`, name: `Assignment ${i}`})))
    this.never_drops = new NeverDropCollection([], {
      assignments: this.assignments,
      ag_id: 'new'
    })
    this.view = new NeverDropCollectionView({
      collection: this.never_drops,
      canChangeDropRules: true
    })

    $('#fixtures')
      .empty()
      .append(this.view.render().el)
  },

  teardown() {
    this.clock.restore()
    useNormalDebounce()
  }
})

const addNeverDrop = function() {
  return this.never_drops.add({
    id: this.never_drops.size(),
    label_id: 'new'
  })
}

test('possibleValues is set to the range of assignment ids', function() {
  deepEqual(this.never_drops.possibleValues, this.assignments.map(a => a.id))
})

test('adding a NeverDrop to the collection reduces availableValues by one', function() {
  const start_length = this.never_drops.availableValues.length
  addNeverDrop.call(this)
  equal(start_length - 1, this.never_drops.availableValues.length)
})

test('adding a NeverDrop renders a <select> with the value from the front of the availableValues collection', function() {
  const expected_val = this.never_drops.availableValues.slice(0)[0].id
  addNeverDrop.call(this)
  this.clock.tick(101)
  const view = $('#fixtures').find('select')
  ok(view.length, 'a select was rendered')
  equal(expected_val, view.val(), 'the selects value is the same as the last available value')
})

test('the number of <option>s with the value the same as availableValue should equal the number of selects', function() {
  addNeverDrop.call(this)
  addNeverDrop.call(this)
  this.clock.tick(101)
  const available_val = this.never_drops.availableValues.at(0).id
  equal($('#fixtures').find(`option[value=${available_val}]`).length, 2)
})

test('removing a NeverDrop from the collection increases availableValues by one', function() {
  addNeverDrop.call(this)
  this.clock.tick(101)
  const current_size = this.never_drops.availableValues.length
  const model = this.never_drops.at(0)
  this.never_drops.remove(model)
  equal(current_size + 1, this.never_drops.availableValues.length)
})

test('removing a NeverDrop from the collection removes the view', function() {
  addNeverDrop.call(this)
  const model = this.never_drops.at(0)
  this.never_drops.remove(model)

  this.clock.tick(101)
  const view = $('#fixtures').find('select')
  equal(view.length, 0)
})

test('changing a <select> will remove all <option>s with that value from other selects', function() {
  addNeverDrop.call(this)
  addNeverDrop.call(this)
  const target_id = '1'

  this.clock.tick(101)
  ok($('#fixtures').find(`option[value=${target_id}]`).length, 2)
  // change one of the selects
  $('#fixtures')
    .find('select:first')
    .val(target_id)
    .trigger('change')

  this.clock.tick(101)
  // should only be one now
  ok($('#fixtures').find(`option[value=${target_id}]`).length, 1)
  // target_id is now taken
  ok(this.never_drops.takenValues.find(nd => nd.id === target_id))
})

test('changing a <select> will add all <option>s with the previous value to other selects', function() {
  addNeverDrop.call(this)
  addNeverDrop.call(this)
  const change_id = '1'
  const target_id = '3'

  this.clock.tick(101)
  // should just have the selected one
  ok($('#fixtures').find(`option[value=${target_id}]`).length, 1)
  // change one of the selects
  $('#fixtures')
    .find('select:first')
    .val(change_id)
    .trigger('change')

  this.clock.tick(101)
  // should now be more than one
  ok($('#fixtures').find(`option[value=${target_id}]`).length, 2)

  // target_id is now available
  ok(this.never_drops.availableValues.find(nd => nd.id === target_id))
})

test('resetting NeverDrops with a chosen assignment renders a <span>', function() {
  const target_id = '1'
  this.never_drops.reset([
    {
      id: this.never_drops.length,
      label_id: 'new',
      chosen: 'Assignment 1',
      chosen_id: target_id
    }
  ])

  this.clock.tick(101)
  ok($('#fixtures').find('span').length, 1)
  ok(this.never_drops.takenValues.find(nd => nd.id === target_id))
})

test('when there are no availableValues, the add assignment link is not rendered', function() {
  addNeverDrop.call(this)
  addNeverDrop.call(this)
  addNeverDrop.call(this)

  this.clock.tick(101)
  equal($('#fixtures').find('.add_never_drop').length, 0)
})

test("when there are no takenValues, the add assignment says 'add an assignment'", function() {
  const text = $('#fixtures')
    .find('.add_never_drop')
    .text()
  equal($.trim(text), 'Add an assignment')
})

test("when there is at least one takenValue, the add assignment says 'add another assignment'", function() {
  addNeverDrop.call(this)
  this.clock.tick(101)
  const text = $('#fixtures')
    .find('.add_never_drop')
    .text()
  equal($.trim(text), 'Add another assignment')
})

test('allows adding never_drop items when canChangeDropRules is true', function() {
  notOk(
    $('#fixtures')
      .find('.add_never_drop')
      .hasClass('disabled')
  )
  $('#fixtures')
    .find('.add_never_drop')
    .trigger('click')
  this.clock.tick(101)
  equal(this.never_drops.length, 1)
})

test('allows removing never_drop items when canChangeDropRules is true', function() {
  addNeverDrop.call(this)
  this.clock.tick(101)
  $('#fixtures')
    .find('.remove_never_drop')
    .trigger('click')
  this.clock.tick(101)
  equal(this.never_drops.length, 0)
})

test('disables adding never_drop items when canChangeDropRules is false', function() {
  this.view.canChangeDropRules = false
  this.view.render() // force re-render
  ok(
    $('#fixtures')
      .find('.add_never_drop')
      .hasClass('disabled')
  )
  $('#fixtures')
    .find('.add_never_drop')
    .trigger('click')
  this.clock.tick(101)
  equal(this.never_drops.length, 0)
})

test('disables removing never_drop items when canChangeDropRules is false', function() {
  addNeverDrop.call(this)
  this.view.canChangeDropRules = false
  this.clock.tick(101)
  ok(
    $('#fixtures')
      .find('.remove_never_drop')
      .hasClass('disabled')
  )
  $('#fixtures')
    .find('.remove_never_drop')
    .trigger('click')
  this.clock.tick(101)
  equal(this.never_drops.length, 1)
})

test('disables changing assignment options when canChangeDropRules is false', function() {
  addNeverDrop.call(this)
  this.view.canChangeDropRules = false
  this.clock.tick(101)
  ok(
    $('#fixtures')
      .find('select:first')
      .attr('readonly')
  )
  $('#fixtures')
    .find('select:first')
    .val('2')
    .trigger('change')
  this.clock.tick(101)
  notOk(this.never_drops.takenValues.find(nd => nd.id === '2'))
})
