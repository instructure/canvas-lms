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
import SelectContentView from 'compiled/views/content_migrations/SelectContentView'
import ProgressingMigration from 'compiled/models/ProgressingContentMigration'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

class SelectContentHelper {
  static initClass() {
    this.url = '/api/v1/courses/42/content_migrations/5/selective_data'
  }
  static $caret() {
    return this.$fixtures.find('.checkbox-caret').first()
  }
  static toplevelCheckboxResponse() {
    return [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify([
        {
          type: 'course_settings',
          property: 'copy[all_course_settings]',
          title: 'Course Settings'
        },
        {
          type: 'syllabus_body',
          property: 'copy[all_syllabus_body]',
          title: 'Syllabus Body'
        },
        {
          count: 2,
          property: 'copy[all_assignments]',
          sub_items_url: this.url + '?type=assignments',
          title: 'Assignments',
          type: 'assignments'
        }
      ])
    ]
  }
  static sublevelCheckboxResponse() {
    return [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify([
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
              migration_id: 'i1a139fc4cbf94f961973c63bd90fc1c7'
            },
            {
              type: 'assignments',
              property: 'copy[assignments][id_i7af74171d7c7207f1578328d8bbf9dae]',
              title: 'Unnamed Quiz',
              migration_id: 'i7af74171d7c7207f1578328d8bbf9dae'
            },
            {
              type: 'assignments',
              property: 'copy[assignments][id_i4af043da2399a5ec221f666b38714fa8]',
              title: 'Unnamed Quiz',
              migration_id: 'i4af043da2399a5ec221f666b38714fa8',
              linked_resource: {
                type: 'assignments',
                migration_id: 'i7af74171d7c7207f1578328d8bbf9dae'
              }
            }
          ]
        }
      ])
    ]
  }
}
SelectContentHelper.initClass()

QUnit.module('SelectContentView: Integration Tests', {
  setup() {
    this.server = sinon.fakeServer.create()
    fakeENV.setup()
    this.$fixtures = $('#fixtures')
    this.model = new ProgressingMigration({
      id: 5,
      course_id: 42
    })

    this.selectContentView = new SelectContentView({
      model: this.model,
      title: 'Select Content',
      width: 600,
      height: 400,
      fixDialogButtons: false
    })

    this.$fixtures.append(this.selectContentView.$el)

    this.server.respondWith(
      'GET',
      SelectContentHelper.url,
      SelectContentHelper.toplevelCheckboxResponse()
    )
    this.selectContentView.open()
    this.server.respond()
    this.tree = this.selectContentView.$el.find('ul[role=tree]')
  },

  teardown() {
    fakeENV.teardown()
    this.server.restore()
    this.selectContentView.remove()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  return assertions.isAccessible(this.selectContentView, done, {a11yReport: true})
})

test('render top level checkboxes when opened', function() {
  const $checkboxes = this.selectContentView.$el.find('[type=checkbox]')
  equal($checkboxes.length, 3, 'Renders all checkboxes')
})

test('changes parents to intermediate when not all of the sublevel checkboxes are check', function() {
  this.server.respondWith(
    'GET',
    SelectContentHelper.url + '?type=assignments',
    SelectContentHelper.sublevelCheckboxResponse()
  )
  this.selectContentView.$el.find('[data-type=assignments] .checkbox-caret').simulate('click')
  this.server.respond()
  const $subCheckboxes = this.selectContentView.$el
    .find('.collectionViewItems')
    .last()
    .find('[type=checkbox]')
  this.selectContentView.$el.find("[data-state='closed']").show()
  this.selectContentView.$el.find($subCheckboxes[2]).simulate('click')
  const indeterminate = this.selectContentView.$el
    .find("input[name='copy[all_assignments]']")
    .first()
    .prop('indeterminate')

  ok(indeterminate || indeterminate === 'true', 'Parent changed to intermediate')
})

test('clicking the caret shows and hides checkboxes', function() {
  const $caret = this.selectContentView.$el.find('[data-type=assignments] .checkbox-caret').first()
  const $sublevelCheckboxes = $caret
    .closest('div')
    .siblings('ul')
    .first()

  equal($caret.parents('[role=treeitem]').attr('aria-expanded'), 'false')
  $caret.simulate('click')

  equal($caret.parents('[role=treeitem]').attr('aria-expanded'), 'true')
})

test('checking a checkbox checks all children checkboxes', function() {
  this.server.respondWith(
    'GET',
    SelectContentHelper.url + '?type=assignments',
    SelectContentHelper.sublevelCheckboxResponse()
  )
  const $assignmentCarrot = this.selectContentView.$el.find(
    '[data-type=assignments] .checkbox-caret'
  )
  $assignmentCarrot.simulate('click')
  this.server.respond()

  const clock = sinon.useFakeTimers()

  this.selectContentView.$el.find("input[name='copy[all_assignments]']").simulate('click')

  clock.tick(1)

  this.selectContentView.$el.find('[data-type=assignments] input[type=checkbox]').each(function() {
    ok($(this).is(':checked'), 'checkbox is checked')
  })
  clock.restore()
})

test('checking toplevel then expanding should also check all children when they are loaded', function() {
  this.server.respondWith(
    'GET',
    SelectContentHelper.url + '?type=assignments',
    SelectContentHelper.sublevelCheckboxResponse()
  )
  this.selectContentView.$el.find("input[name='copy[all_assignments]']").simulate('click')

  const clock = sinon.useFakeTimers()
  const $assignmentCarrot = this.selectContentView.$el.find(
    '[data-type=assignments] .checkbox-caret'
  )
  $assignmentCarrot.simulate('click')
  this.server.respond()

  clock.tick(1)
  this.selectContentView.$el.find('[data-type=assignments] input[type=checkbox]').each(function() {
    ok($(this).is(':checked'), 'checkbox is checked')
  })

  clock.restore()
})

test('pressing the cancel button closes the dialog view', function() {
  this.selectContentView.$el.find('#cancelSelect').simulate('click')
  ok(!this.selectContentView.dialog.isOpen(), 'Dialog is closed')
})

test('select content button is disabled unless content is selected', function() {
  ok(this.selectContentView.$el.find('#selectContentBtn').prop('disabled'), 'Disabled by default')
  this.selectContentView.$el
    .find('input[type=checkbox]')
    .first()
    .simulate('click')
  ok(
    !this.selectContentView.$el.find('#selectContentBtn').prop('disabled'),
    'Enabled after checking item'
  )
  this.selectContentView.$el
    .find('input[type=checkbox]')
    .first()
    .simulate('click')
  ok(
    this.selectContentView.$el.find('#selectContentBtn').prop('disabled'),
    're-disabled if no selected'
  )
})

test('pressing the up/down arrow selects the next treeitem', function() {
  const downEvent = jQuery.Event('keyup', {which: 40})
  const upEvent = jQuery.Event('keyup', {which: 38})

  const $treeitems = this.selectContentView.$el.find('[role=treeitem]:visible')
  this.tree = this.selectContentView.$el.find('ul[role=tree]')

  this.tree.trigger(downEvent)
  this.tree.trigger(downEvent)
  let $currentlySelected = this.selectContentView.$el.find('[aria-selected=true]')
  equal($treeitems.index($currentlySelected), 1, 'pressing down moves to the second item')

  this.tree.trigger(upEvent)
  $currentlySelected = this.selectContentView.$el.find('[aria-selected=true]')
  equal($treeitems.index($currentlySelected), 0, 'pressing up moves to the first item')
})

test('pressing home/end buttons move you to the first and last treeitem', function() {
  const homeEvent = jQuery.Event('keyup', {which: 36})
  const endEvent = jQuery.Event('keyup', {which: 35})
  const $treeitems = this.selectContentView.$el.find('[role=treeitem]:visible')

  this.tree.trigger(endEvent)
  let $currentlySelected = this.selectContentView.$el.find('[aria-selected=true]')
  equal(
    $treeitems.index($currentlySelected),
    $treeitems.length - 1,
    'pressing the end button moves to last item'
  )

  this.tree.trigger(homeEvent)
  $currentlySelected = this.selectContentView.$el.find('[aria-selected=true]')
  equal($treeitems.index($currentlySelected), 0, 'pressing the home button moves to the first item')
})

test('pressing right arrow expands', function() {
  const rightEvent = jQuery.Event('keyup', {which: 39})
  const downEvent = jQuery.Event('keyup', {which: 40})

  this.tree.trigger(downEvent)
  this.tree.trigger(downEvent)
  this.tree.trigger(downEvent)
  this.tree.trigger(rightEvent)

  const $currentlySelected = this.selectContentView.$el.find('[aria-selected=true]')
  equal(
    $currentlySelected.attr('aria-expanded'),
    'true',
    'expands the tree item when right is pressed'
  )
})

test('aria levels are correctly represented', function() {
  this.server.respondWith(
    'GET',
    SelectContentHelper.url + '?type=assignments',
    SelectContentHelper.sublevelCheckboxResponse()
  )
  this.selectContentView.$el.find("input[name='copy[all_assignments]']").simulate('click')

  const clock = sinon.useFakeTimers()
  const $assignmentCarrot = this.selectContentView.$el.find(
    '[data-type=assignments] .checkbox-caret'
  )
  $assignmentCarrot.simulate('click')
  this.server.respond()

  clock.tick(1)

  equal(
    this.selectContentView.$el
      .find("[name='copy[all_assignments]']")
      .parents('[role=treeitem]')
      .attr('aria-level'),
    '1',
    'top level aria level is 1'
  )
  equal(
    this.selectContentView.$el
      .find("[name='copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]']")
      .parents('[role=treeitem]')
      .attr('aria-level'),
    '2',
    'second level has a level of 2'
  )

  clock.restore()
})

test('active decendant is set propertly when clicking on treeitems', function() {
  const $tree = this.selectContentView.$el.find('[role=tree]')
  const $treeitem = this.selectContentView.$el.find('[role=treeitem]:first')
  const $treeitemHeading = this.selectContentView.$el.find(
    '[role=treeitem]:first .treeitem-heading'
  )

  $treeitemHeading.click()

  equal($tree.attr('aria-activedescendant'), $treeitem.attr('id'))
})
