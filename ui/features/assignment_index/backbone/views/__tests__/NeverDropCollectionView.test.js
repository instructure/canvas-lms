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
import {fireEvent, waitFor} from '@testing-library/react'

// Mock debounce and defer to make them synchronous for testing
// NeverDropCollectionView uses es-toolkit/compat for debounce
// NeverDropView uses es-toolkit/compat for defer
vi.mock('es-toolkit/compat', async () => {
  const actual = await vi.importActual('es-toolkit/compat')
  return {
    ...actual,
    debounce: fn => fn,
    defer: fn => fn(),
  }
})

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
  beforeAll(() => {
    // Create the fixtures container
    const fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
  })

  afterAll(() => {
    const fixtures = document.getElementById('fixtures')
    if (fixtures) {
      fixtures.remove()
    }
  })

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

  afterEach(() => {
    view.remove()
    $('#fixtures').empty()
  })

  it('possibleValues is set to the range of assignment ids', function () {
    expect(never_drops.possibleValues).toEqual(assignments.map(a => a.id))
  })

  it('adding a NeverDrop to the collection reduces availableValues by one', function () {
    const start_length = never_drops.availableValues.length
    addNeverDrop()
    expect(never_drops.availableValues).toHaveLength(start_length - 1)
  })

  it('adding a NeverDrop renders a <select> with the value from the front of the availableValues collection', async function () {
    const expected_val = never_drops.availableValues.slice(0)[0].id
    addNeverDrop()
    await waitFor(() => {
      const select = $('#fixtures').find('select')
      expect(select.length).toBeGreaterThan(0)
      expect(select.val()).toBe(expected_val)
    })
  })

  it('the number of <option>s with the value the same as availableValue should equal the number of selects', async function () {
    addNeverDrop()
    addNeverDrop()
    await waitFor(() => {
      const available_val = never_drops.availableValues.at(0).id
      expect($('#fixtures').find(`option[value="${available_val}"]`)).toHaveLength(2)
    })
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

  it('changing a <select> will remove all <option>s with that value from other selects', async function () {
    addNeverDrop()
    addNeverDrop()
    // After adding two NeverDrops, each takes a value (1 and 2), but 3 is available in both
    const target_id = '3'

    await waitFor(() => {
      // Both selects have option value="3" available
      expect($('#fixtures').find(`option[value="${target_id}"]`)).toHaveLength(2)
    })

    const selectElement = $('#fixtures').find('select:first')[0]
    selectElement.value = target_id
    fireEvent.change(selectElement)

    await waitFor(() => {
      // After changing first select to 3, option 3 should only appear in first select
      expect($('#fixtures').find(`option[value="${target_id}"]`)).toHaveLength(1)
      expect(never_drops.takenValues.find(nd => nd.id === target_id)).toBeTruthy()
    })
  })

  it('changing a <select> will add all <option>s with the previous value to other selects', async function () {
    addNeverDrop()
    addNeverDrop()
    // After adding two NeverDrops: first has 1, second has 2
    // Option 3 is available in both (2 occurrences)
    // Option 1 is only in first select (1 occurrence)

    // First, change first select to 3 (takes 3 away from second)
    await waitFor(() => {
      expect($('#fixtures').find(`option[value="3"]`)).toHaveLength(2)
    })

    const selectElement = $('#fixtures').find('select:first')[0]
    selectElement.value = '3'
    fireEvent.change(selectElement)

    await waitFor(() => {
      // After change: first has 3, so option 1 becomes available to second select
      // Option 1 should now appear in the second select (2 total: first has it available, second has it available)
      expect($('#fixtures').find(`option[value="1"]`)).toHaveLength(2)
      expect(never_drops.availableValues.find(nd => nd.id === '1')).toBeTruthy()
    })
  })

  it('resetting NeverDrops with a chosen assignment renders a <span>', async function () {
    const target_id = '1'
    never_drops.reset([
      {
        id: never_drops.length,
        label_id: 'new',
        chosen: 'Assignment 1',
        chosen_id: target_id,
      },
    ])

    await waitFor(() => {
      expect($('#fixtures').find('[data-testid="chosen-assignment"]')).toHaveLength(1)
      expect(never_drops.takenValues.find(nd => nd.id === target_id)).toBeTruthy()
    })
  })

  it('when there are no availableValues, the add assignment link is not rendered', function () {
    addNeverDrop()
    addNeverDrop()
    addNeverDrop()
    expect($('#fixtures').find('.add_never_drop')).toHaveLength(0)
  })

  it("when there is at least one takenValue, the add assignment says 'add another assignment'", async function () {
    addNeverDrop()
    await waitFor(() => {
      const text = $('#fixtures').find('.add_never_drop').text()
      expect($.trim(text)).toContain('Add another assignment')
    })
  })

  it('allows adding never_drop items when canChangeDropRules is true', async function () {
    expect($('#fixtures').find('.add_never_drop').hasClass('disabled')).not.toBeTruthy()
    const addButton = $('#fixtures').find('.add_never_drop')[0]
    fireEvent.click(addButton)
    await waitFor(() => {
      expect(never_drops).toHaveLength(1)
    })
  })

  it('allows removing never_drop items when canChangeDropRules is true', async function () {
    addNeverDrop()
    await waitFor(() => {
      expect($('#fixtures').find('.remove_never_drop')).toHaveLength(1)
    })
    const removeButton = $('#fixtures').find('.remove_never_drop')[0]
    fireEvent.click(removeButton)
    await waitFor(() => {
      expect(never_drops).toHaveLength(0)
    })
  })

  it('disables adding never_drop items when canChangeDropRules is false', async function () {
    view.canChangeDropRules = false
    view.render()
    await waitFor(() => {
      expect($('#fixtures').find('.add_never_drop').hasClass('disabled')).toBeTruthy()
    })
    const addButton = $('#fixtures').find('.add_never_drop')[0]
    fireEvent.click(addButton)
    // Should not add because canChangeDropRules is false
    expect(never_drops).toHaveLength(0)
  })

  it('disables removing never_drop items when canChangeDropRules is false', async function () {
    addNeverDrop()
    view.canChangeDropRules = false
    view.render()
    await waitFor(() => {
      expect($('#fixtures').find('.remove_never_drop').hasClass('disabled')).toBeTruthy()
    })
    const removeButton = $('#fixtures').find('.remove_never_drop')[0]
    fireEvent.click(removeButton)
    // Should not remove because canChangeDropRules is false
    expect(never_drops).toHaveLength(1)
  })

  it('disables changing assignment options when canChangeDropRules is false', async function () {
    addNeverDrop()
    view.canChangeDropRules = false
    view.render()
    await waitFor(() => {
      expect($('#fixtures').find('select:first').attr('disabled')).toBeTruthy()
    })
    const selectElement = $('#fixtures').find('select:first')[0]
    selectElement.value = '2'
    fireEvent.change(selectElement)
    // Should not change because canChangeDropRules is false
    expect(never_drops.takenValues.find(nd => nd.id === '2')).not.toBeTruthy()
  })

  it("when there are no takenValues, the add assignment says 'add an assignment'", () => {
    const text = $('#fixtures').find('.add_never_drop').text()
    expect($.trim(text)).toContain('Add an assignment')
  })
})
