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
import SectionMenuView from 'compiled/views/gradebook/SectionMenuView'
import 'vendor/jquery.ba-tinypubsub'

const sections = [
  {
    id: 1,
    name: 'Section One',
    checked: true
  },
  {
    id: 2,
    name: 'Section Two',
    checked: false
  }
]
const course = {
  id: 1,
  name: 'Course One',
  checked: false
}
const currentSection = 1

QUnit.module('gradebook/SectionMenuView', {
  setup() {
    this.view = new SectionMenuView({
      sections,
      currentSection,
      course
    })
    this.view.render()
    return this.view.$el.appendTo('#fixtures')
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('it renders a button', function() {
  ok(this.view.$el.find('button').length, 'button displays')
  ok(
    this.view.$el
      .find('button')
      .text()
      .match(/Section One/),
    'button label includes current section'
  )
})

test('it displays given sections', function() {
  const clock = sinon.useFakeTimers()
  this.view.$el.find('button').click()
  clock.tick(101)
  const html = $('.section-select-menu:visible').html()
  ok(html.match(/All Sections/), 'displays default "all sections"')
  ok(html.match(/Section One/), 'displays first section')
  ok(html.match(/Section Two/), 'displays section section')
  return clock.restore()
})

test('it changes sections', function() {
  this.view.$el.find('button').click()
  $('input[value=2]')
    .parent()
    .click()
  ok(this.view.currentSection === '2', 'updates its section')
})

test('it publishes changes', function(assert) {
  const start = assert.async()
  assert.expect(1)
  $.subscribe('currentSection/change', section => {
    ok(section === '2', 'publish fires')
    return start()
  })
  this.view.$el.find('button').click()
  $('input[value=2]')
    .parent()
    .click()
  return $.unsubscribe('currentSection/change')
})
