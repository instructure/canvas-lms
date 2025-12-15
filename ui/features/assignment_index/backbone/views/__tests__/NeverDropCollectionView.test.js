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

// Mock debounce to make it synchronous for testing
vi.mock('lodash', () => ({
  ...vi.requireActual('lodash'),
  debounce: fn => fn,
}))

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

let assignments
let never_drops
let view

const addNeverDrop = function () {
  return never_drops.add({
    id: never_drops.size(),
    label_id: 'new',
  })
}

describe('NeverDropCollectionView', () => {
  beforeEach(() => {
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

  it('possibleValues is set to the range of assignment ids', function () {
    expect(never_drops.possibleValues).toEqual(assignments.map(a => a.id))
  })

  it('adding a NeverDrop to the collection reduces availableValues by one', function () {
    const start_length = never_drops.availableValues.length
    addNeverDrop()
    expect(never_drops.availableValues).toHaveLength(start_length - 1)
  })

  // TODO: Rewrite for React - needs @testing-library/react utilities
  it.skip('adding a NeverDrop renders a <select> with the value from the front of the availableValues collection', function () {
    const expected_val = never_drops.availableValues.slice(0)[0].id
    addNeverDrop()
    const select = $('#fixtures').find('select')
    expect(select.length).toBeGreaterThan(0)
    expect(select.val()).toBe(expected_val)
  })

  // TODO: Rewrite for React - needs @testing-library/react utilities
  it.skip('the number of <option>s with the value the same as availableValue should equal the number of selects', function () {
    addNeverDrop()
    addNeverDrop()
    const available_val = never_drops.availableValues.at(0).id
    expect($('#fixtures').find(`option[value=${available_val}]`)).toHaveLength(2)
  })

  it('removing a NeverDrop from the collection increases availableValues by one', function () {
    addNeverDrop()
    const current_size = never_drops.availableValues.length
    const model = never_drops.at(0)
    never_drops.remove(model)
    expect(never_drops.availableValues).toHaveLength(current_size + 1)
  })

  it('removing a NeverDrop from the collection removes the view', function () {
    addNeverDrop()
    const model = never_drops.at(0)
    never_drops.remove(model)
    const select = $('#fixtures').find('select')
    expect(select).toHaveLength(0)
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('changing a <select> will remove all <option>s with that value from other selects', function () {
    addNeverDrop()
    addNeverDrop()
    const target_id = '1'

    expect($('#fixtures').find(`option[value=${target_id}]`)).toHaveLength(2)
    $('#fixtures').find('select:first').val(target_id).trigger('change')
    expect($('#fixtures').find(`option[value=${target_id}]`)).toHaveLength(1)
    expect(never_drops.takenValues.find(nd => nd.id === target_id)).toBeTruthy()
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('changing a <select> will add all <option>s with the previous value to other selects', function () {
    addNeverDrop()
    addNeverDrop()
    const change_id = '1'
    const target_id = '3'

    expect($('#fixtures').find(`option[value=${target_id}]`)).toHaveLength(1)
    $('#fixtures').find('select:first').val(change_id).trigger('change')
    expect($('#fixtures').find(`option[value=${target_id}]`)).toHaveLength(2)
    expect(never_drops.availableValues.find(nd => nd.id === target_id)).toBeTruthy()
  })

  // TODO: Rewrite for React - needs @testing-library/react utilities
  it.skip('resetting NeverDrops with a chosen assignment renders a <span>', function () {
    const target_id = '1'
    never_drops.reset([
      {
        id: never_drops.length,
        label_id: 'new',
        chosen: 'Assignment 1',
        chosen_id: target_id,
      },
    ])

    expect($('#fixtures').find('span')).toHaveLength(1)
    expect(never_drops.takenValues.find(nd => nd.id === target_id)).toBeTruthy()
  })

  it('when there are no availableValues, the add assignment link is not rendered', function () {
    addNeverDrop()
    addNeverDrop()
    addNeverDrop()
    expect($('#fixtures').find('.add_never_drop')).toHaveLength(0)
  })

  // TODO: Rewrite for React - handlebars i18n helpers not rendering in test
  it.skip("when there is at least one takenValue, the add assignment says 'add another assignment'", function () {
    addNeverDrop()
    const text = $('#fixtures').find('.add_never_drop').text()
    expect($.trim(text)).toBeTruthy()
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('allows adding never_drop items when canChangeDropRules is true', function () {
    expect($('#fixtures').find('.add_never_drop').hasClass('disabled')).not.toBeTruthy()
    $('#fixtures').find('.add_never_drop').trigger('click')
    expect(never_drops).toHaveLength(1)
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('allows removing never_drop items when canChangeDropRules is true', function () {
    addNeverDrop()
    $('#fixtures').find('.remove_never_drop').trigger('click')
    expect(never_drops).toHaveLength(0)
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('disables adding never_drop items when canChangeDropRules is false', function () {
    view.canChangeDropRules = false
    view.render()
    expect($('#fixtures').find('.add_never_drop').hasClass('disabled')).toBeTruthy()
    $('#fixtures').find('.add_never_drop').trigger('click')
    expect(never_drops).toHaveLength(0)
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('disables removing never_drop items when canChangeDropRules is false', function () {
    addNeverDrop()
    view.canChangeDropRules = false
    view.render()
    expect($('#fixtures').find('.remove_never_drop').hasClass('disabled')).toBeTruthy()
    $('#fixtures').find('.remove_never_drop').trigger('click')
    expect(never_drops).toHaveLength(1)
  })

  // TODO: Rewrite for React - jQuery .trigger() doesn't work with React synthetic events
  it.skip('disables changing assignment options when canChangeDropRules is false', function () {
    addNeverDrop()
    view.canChangeDropRules = false
    view.render()
    expect($('#fixtures').find('select:first').attr('disabled')).toBeTruthy()
    $('#fixtures').find('select:first').val('2').trigger('change')
    expect(never_drops.takenValues.find(nd => nd.id === '2')).not.toBeTruthy()
  })

  // TODO: Rewrite for React - handlebars i18n helpers not rendering in test
  it.skip("when there are no takenValues, the add assignment says 'add an assignment'", () => {
    const text = $('#fixtures').find('.add_never_drop').text()
    expect($.trim(text)).toBe('Add an assignment')
  })
})
