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
import Backbone from '@canvas/backbone'
import NeverDropCollection from '../../collections/NeverDropCollection'
import NeverDropCollectionView from '../NeverDropCollectionView'
import sinon from 'sinon'

class AssignmentStub extends Backbone.Model {
  name() {
    return this.get('name')
  }

  toView() {
    return {
      name: this.get('name'),
      id: this.id,
    }
  }
}

class Assignments extends Backbone.Collection {
  static initClass() {
    this.prototype.model = AssignmentStub
  }
}
Assignments.initClass()

let clock
let assignments
let never_drops
let view

const addNeverDrop = function () {
  return never_drops.add({
    id: never_drops.size(),
    label_id: 'new',
  })
}

// EVAL-3815
describe('NeverDropCollectionView', () => {
  beforeEach(() => {
    clock = sinon.useFakeTimers()
    assignments = new Assignments([1, 2, 3].map(i => ({id: `${i}`, name: `Assignment ${i}`})))
    never_drops = new NeverDropCollection([], {
      assignments,
      ag_id: 'new',
    })
    view = new NeverDropCollectionView({
      collection: never_drops,
      canChangeDropRules: true,
    })

    $('#fixtures').empty().append(view.render().el)
  })

  afterEach(() => {
    clock.restore()
  })

  it.skip('possibleValues is set to the range of assignment ids', function () {
    expect(never_drops.possibleValues).toBe(assignments.map(a => a.id))
  })

  it.skip('adding a NeverDrop to the collection reduces availableValues by one', function () {
    const start_length = never_drops.availableValues.length
    addNeverDrop.call(this)
    expect(start_length - 1).toBe(never_drops.availableValues.length)
  })

  it.skip('needs rewrite due to debounce hack', () => {
    test('adding a NeverDrop renders a <select> with the value from the front of the availableValues collection', function () {
      const expected_val = never_drops.availableValues.slice(0)[0].id
      addNeverDrop.call(this)
      clock.tick(101)
      const view = $('#fixtures').find('select')
      // 'a select was rendered'
      expect(view.length).toBeGreaterThan(1)
      // 'the selects value is the same as the last available value'
      expect(expected_val).toBe(view.val())
    })

    test('the number of <option>s with the value the same as availableValue should equal the number of selects', function () {
      addNeverDrop.call(this)
      addNeverDrop.call(this)
      clock.tick(101)
      const available_val = never_drops.availableValues.at(0).id
      expect($('#fixtures').find(`option[value=${available_val}]`).length).toBe(2)
    })

    test('removing a NeverDrop from the collection increases availableValues by one', function () {
      addNeverDrop.call(this)
      clock.tick(101)
      const current_size = never_drops.availableValues.length
      const model = never_drops.at(0)
      never_drops.remove(model)
      expect(current_size + 1).toBe(never_drops.availableValues.length)
    })

    test('removing a NeverDrop from the collection removes the view', function () {
      addNeverDrop.call(this)
      const model = never_drops.at(0)
      never_drops.remove(model)

      clock.tick(101)
      const view = $('#fixtures').find('select')
      expect(view.length).toBe(0)
    })

    test('changing a <select> will remove all <option>s with that value from other selects', function () {
      addNeverDrop.call(this)
      addNeverDrop.call(this)
      const target_id = '1'

      clock.tick(101)
      expect($('#fixtures').find(`option[value=${target_id}]`).length).toBe(2)
      // change one of the selects
      $('#fixtures').find('select:first').val(target_id).trigger('change')

      clock.tick(101)
      // should only be one now
      expect($('#fixtures').find(`option[value=${target_id}]`).length).toBe(1)
      // target_id is now taken
      expect(never_drops.takenValues.find(nd => nd.id === target_id)).toBeTruthy()
    })

    test('changing a <select> will add all <option>s with the previous value to other selects', function () {
      addNeverDrop.call(this)
      addNeverDrop.call(this)
      const change_id = '1'
      const target_id = '3'

      clock.tick(101)
      // should just have the selected one
      expect($('#fixtures').find(`option[value=${target_id}]`).length).toBe(1)
      // change one of the selects
      $('#fixtures').find('select:first').val(change_id).trigger('change')

      clock.tick(101)
      // should now be more than one
      expect($('#fixtures').find(`option[value=${target_id}]`).length).toBe(2)

      // target_id is now available
      expect(never_drops.availableValues.find(nd => nd.id === target_id)).toBeTruthy()
    })

    test('resetting NeverDrops with a chosen assignment renders a <span>', function () {
      const target_id = '1'
      never_drops.reset([
        {
          id: never_drops.length,
          label_id: 'new',
          chosen: 'Assignment 1',
          chosen_id: target_id,
        },
      ])

      clock.tick(101)
      expect($('#fixtures').find('span').length).toBe(1)
      expect(never_drops.takenValues.find(nd => nd.id === target_id)).toBeTruthy()
    })

    test('when there are no availableValues, the add assignment link is not rendered', function () {
      addNeverDrop.call(this)
      addNeverDrop.call(this)
      addNeverDrop.call(this)

      clock.tick(101)
      expect($('#fixtures').find('.add_never_drop').length).toBe(0)
    })

    test("when there is at least one takenValue, the add assignment says 'add another assignment'", function () {
      addNeverDrop.call(this)
      clock.tick(101)
      const text = $('#fixtures').find('.add_never_drop').text()
      // 'Add another assignment'
      expect($.trim(text)).toBeTruthy()
    })

    test('allows adding never_drop items when canChangeDropRules is true', function () {
      expect($('#fixtures').find('.add_never_drop').hasClass('disabled')).not.toBeTruthy()
      $('#fixtures').find('.add_never_drop').trigger('click')
      clock.tick(101)
      expect(never_drops.length).toBe(1)
    })

    test('allows removing never_drop items when canChangeDropRules is true', function () {
      addNeverDrop.call(this)
      clock.tick(101)
      $('#fixtures').find('.remove_never_drop').trigger('click')
      clock.tick(101)
      expect(never_drops.length).toBe(0)
    })

    test('disables adding never_drop items when canChangeDropRules is false', function () {
      view.canChangeDropRules = false
      view.render() // force re-render
      expect($('#fixtures').find('.add_never_drop').hasClass('disabled')).toBeTruthy()
      $('#fixtures').find('.add_never_drop').trigger('click')
      clock.tick(101)
      expect(never_drops.length).toBe(0)
    })

    test('disables removing never_drop items when canChangeDropRules is false', function () {
      addNeverDrop.call(this)
      view.canChangeDropRules = false
      clock.tick(101)
      expect($('#fixtures').find('.remove_never_drop').hasClass('disabled')).toBeTruthy()
      $('#fixtures').find('.remove_never_drop').trigger('click')
      clock.tick(101)
      expect(never_drops.length).toBe(1)
    })

    test('disables changing assignment options when canChangeDropRules is false', function () {
      addNeverDrop.call(this)
      view.canChangeDropRules = false
      clock.tick(101)
      expect($('#fixtures').find('select:first').attr('readonly')).toBeTruthy()
      $('#fixtures').find('select:first').val('2').trigger('change')
      clock.tick(101)
      expect(never_drops.takenValues.find(nd => nd.id === '2')).not.toBeTruthy()
    })

    test("when there are no takenValues, the add assignment says 'add an assignment'", () => {
      const text = $('#fixtures').find('.add_never_drop').text()
      expect($.trim(text)).toBe('Add an assignment')
    })
  })
})
