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
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import ProgressingMigration from '../../models/ProgressingContentMigration'
import SelectContentView from '../SelectContentView'
import '@canvas/jquery/jquery.simulate'
import {waitFor} from '@testing-library/dom'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {isAccessible} from '@canvas/test-utils/assertions'

const SELECTIVE_DATA_URL = '/api/v1/courses/42/content_migrations/5/selective_data'

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

describe('SelectContentView: Integration Tests', () => {
  let $fixtures
  let model
  let selectContentView
  let tree

  beforeEach(() => {
    fakeENV.setup()
    $fixtures = $('#fixtures')
    model = new ProgressingMigration({
      id: 5,
      course_id: 42,
    })

    selectContentView = new SelectContentView({
      model,
      title: 'Select Content',
      width: 600,
      height: 400,
      fixDialogButtons: false,
    })

    $fixtures.append(selectContentView.$el)

    // Set up handlers for both top-level and sub-level requests
    server.use(
      http.get(SELECTIVE_DATA_URL, ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('type') === 'assignments') {
          // Return sub-level response
          return HttpResponse.json([
            {
              type: 'assignment_groups',
              property: 'copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]',
              title: 'Assignment group',
              migration_id: 'i6314c45816f1cc6d9519d88e4b7f64ab',
              sub_items: [
                {
                  type: 'assignments',
                  property: 'copy[assignments][id_i1a139fc4cbf94f961973c63bd90fc1c7]',
                  title: 'Assignment 1',
                  migration_id: 'i1a139fc4cbf94f961973c63bd90fc1c7',
                },
                {
                  type: 'assignments',
                  property: 'copy[assignments][id_i7af74171d7c7207f1578328d8bbf9dae]',
                  title: 'Unnamed Quiz',
                  migration_id: 'i7af74171d7c7207f1578328d8bbf9dae',
                },
                {
                  type: 'assignments',
                  property: 'copy[assignments][id_i4af043da2399a5ec221f666b38714fa8]',
                  title: 'Unnamed Quiz',
                  migration_id: 'i4af043da2399a5ec221f666b38714fa8',
                  linked_resource: {
                    type: 'assignments',
                    migration_id: 'i7af74171d7c7207f1578328d8bbf9dae',
                  },
                },
              ],
            },
          ])
        }
        // Return top-level response
        return HttpResponse.json([
          {
            type: 'course_settings',
            property: 'copy[all_course_settings]',
            title: 'Course Settings',
          },
          {
            type: 'syllabus_body',
            property: 'copy[all_syllabus_body]',
            title: 'Syllabus Body',
          },
          {
            count: 2,
            property: 'copy[all_assignments]',
            sub_items_url: SELECTIVE_DATA_URL + '?type=assignments',
            title: 'Assignments',
            type: 'assignments',
          },
        ])
      }),
    )
    selectContentView.open()
    tree = selectContentView.$el.find('ul[role=tree]')
  })

  afterEach(() => {
    fakeENV.teardown()
    selectContentView.remove()
  })

  test('it should be accessible', async () => {
    await new Promise(resolve => setTimeout(resolve, 100))
    await isAccessible(selectContentView, {a11yReport: true})
  })

  test('render top level checkboxes when opened', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    const $checkboxes = selectContentView.$el.find('[type=checkbox]')
    // equal($checkboxes.length, 3, 'Renders all checkboxes')
    expect($checkboxes).toHaveLength(3)
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('changes parents to intermediate when not all of the sublevel checkboxes are check', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    selectContentView.$el.find('[data-type=assignments] .checkbox-caret').simulate('click')
    await new Promise(resolve => setTimeout(resolve, 200))

    const $subCheckboxes = selectContentView.$el
      .find('.collectionViewItems')
      .last()
      .find('[type=checkbox]')

    if ($subCheckboxes.length > 0) {
      selectContentView.$el.find("[data-state='closed']").show()
      $subCheckboxes.last().simulate('click')
      await new Promise(resolve => setTimeout(resolve, 50))

      const indeterminate = selectContentView.$el
        .find("input[name='copy[all_assignments]']")
        .first()
        .prop('indeterminate')

      expect(indeterminate).toBeTruthy()
    }
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('clicking the caret shows and hides checkboxes', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    const $caret = selectContentView.$el.find('[data-type=assignments] .checkbox-caret').first()
    const $treeitem = $caret.parents('[role=treeitem]')

    expect($treeitem.attr('aria-expanded')).toBe('false')
    $caret.simulate('click')
    await new Promise(resolve => setTimeout(resolve, 10))

    expect($treeitem.attr('aria-expanded')).toBe('true')
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('checking a checkbox checks all children checkboxes', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    const $assignmentCarrot = selectContentView.$el.find('[data-type=assignments] .checkbox-caret')
    $assignmentCarrot.simulate('click')
    await new Promise(resolve => setTimeout(resolve, 100))

    selectContentView.$el.find("input[name='copy[all_assignments]']").simulate('click')
    await new Promise(resolve => setTimeout(resolve, 10))

    selectContentView.$el.find('[data-type=assignments] input[type=checkbox]').each(function () {
      expect($(this).is(':checked')).toBeTruthy()
    })
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('checking toplevel then expanding should also check all children when they are loaded', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    selectContentView.$el.find("input[name='copy[all_assignments]']").simulate('click')
    const $assignmentCarrot = selectContentView.$el.find('[data-type=assignments] .checkbox-caret')
    $assignmentCarrot.simulate('click')
    await new Promise(resolve => setTimeout(resolve, 100))
    selectContentView.$el.find('[data-type=assignments] input[type=checkbox]').each(function () {
      expect($(this).is(':checked')).toBeTruthy()
    })
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('pressing the cancel button closes the dialog view', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    selectContentView.$el.find('#cancelSelect').simulate('click')
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(selectContentView.dialog.isOpen()).toBeFalsy()
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('select content button is disabled unless content is selected', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    expect(selectContentView.$el.find('#selectContentBtn').prop('disabled')).toBeTruthy()
    selectContentView.$el.find('input[type=checkbox]').first().simulate('click')
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(selectContentView.$el.find('#selectContentBtn').prop('disabled')).toBeFalsy()
    selectContentView.$el.find('input[type=checkbox]').first().simulate('click')
    await new Promise(resolve => setTimeout(resolve, 10))
    expect(selectContentView.$el.find('#selectContentBtn').prop('disabled')).toBeTruthy()
  })

  // fails with jsdom 25
  test.skip('pressing the up/down arrow selects the next treeitem', function () {
    const downEvent = $.Event('keyup', {which: 40})
    const upEvent = $.Event('keyup', {which: 38})

    const $treeitems = selectContentView.$el.find('[role=treeitem]:visible')
    tree = selectContentView.$el.find('ul[role=tree]')

    tree.trigger(downEvent)
    tree.trigger(downEvent)
    let $currentlySelected = selectContentView.$el.find('[aria-selected=true]')
    expect($treeitems.index($currentlySelected)).toBe(1)

    tree.trigger(upEvent)
    $currentlySelected = selectContentView.$el.find('[aria-selected=true]')
    expect($treeitems.index($currentlySelected)).toBe(0)
  })

  // fails with jsdom 25
  test.skip('pressing home/end buttons move you to the first and last treeitem', async function () {
    const homeEvent = $.Event('keyup', {which: 36})
    const endEvent = $.Event('keyup', {which: 35})
    const $treeitems = selectContentView.$el.find('[role=treeitem]:visible')

    tree.trigger(endEvent)
    let $currentlySelected = selectContentView.$el.find('[aria-selected=true]')
    await waitFor(() => {
      expect($treeitems.index($currentlySelected)).toBe($treeitems.length - 1)
    })

    tree.trigger(homeEvent)
    $currentlySelected = selectContentView.$el.find('[aria-selected=true]')
    await waitFor(() => {
      expect($treeitems.index($currentlySelected)).toEqual(0)
    })
  })

  test('pressing right arrow expands', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))

    // Navigate to assignments item which is expandable
    const $assignmentItem = selectContentView.$el.find('[data-type=assignments]')
    expect($assignmentItem.length).toBeGreaterThan(0)

    // Click on the treeitem to select it
    $assignmentItem.find('.treeitem-heading').first().click()
    await new Promise(resolve => setTimeout(resolve, 10))

    // Now trigger right arrow to expand
    const rightEvent = $.Event('keyup', {which: 39})
    const $tree = selectContentView.$el.find('ul[role=tree]')
    $tree.trigger(rightEvent)
    await new Promise(resolve => setTimeout(resolve, 50))

    // Check if it expanded
    expect($assignmentItem.attr('aria-expanded')).toBe('true')
  })

  // fails with jsdom 25 - jquery.simulate incompatibility
  test.skip('aria levels are correctly represented', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    selectContentView.$el.find("input[name='copy[all_assignments]']").simulate('click')

    const $assignmentCarrot = selectContentView.$el.find('[data-type=assignments] .checkbox-caret')
    $assignmentCarrot.simulate('click')
    await new Promise(resolve => setTimeout(resolve, 100))

    expect(
      selectContentView.$el
        .find("[name='copy[all_assignments]']")
        .parents('[role=treeitem]')
        .attr('aria-level'),
    ).toBe('1')

    expect(
      selectContentView.$el
        .find("[name='copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]']")
        .parents('[role=treeitem]')
        .attr('aria-level'),
    ).toBe('2')
  })

  test('active decendant is set propertly when clicking on treeitems', async function () {
    await new Promise(resolve => setTimeout(resolve, 100))
    const $tree = selectContentView.$el.find('[role=tree]')
    const $treeitem = selectContentView.$el.find('[role=treeitem]:first')
    const $treeitemHeading = selectContentView.$el.find('[role=treeitem]:first .treeitem-heading')

    $treeitemHeading.click()
    await new Promise(resolve => setTimeout(resolve, 10))

    expect($tree.attr('aria-activedescendant')).toBe($treeitem.attr('id'))
  })
})
