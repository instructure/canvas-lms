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
import SectionMenuView from '../SectionMenuView'
import 'jquery-tinypubsub'

const sections = [
  {
    id: 1,
    name: 'Section One',
    checked: true,
  },
  {
    id: 2,
    name: 'Section Two',
    checked: false,
  },
]
const course = {
  id: 1,
  name: 'Course One',
  checked: false,
}
const currentSection = 1

describe('gradebook/SectionMenuView', () => {
  let view

  beforeEach(() => {
    view = new SectionMenuView({
      sections,
      currentSection,
      course,
    })
    view.render()
    $('#fixtures').append(view.$el)
  })

  afterEach(() => {
    $('#fixtures').empty()
  })

  test('it renders a button', () => {
    expect(view.$el.find('button').length).toBeGreaterThan(0)
    expect(view.$el.find('button').text()).toMatch(/Section One/)
  })

  // FOO-4485
  test.skip('it displays given sections', () => {
    jest.useFakeTimers()
    view.$el.find('button').click()
    jest.advanceTimersByTime(101)
    const html = $('.section-select-menu:visible').html()
    expect(html).toMatch(/All Sections/)
    expect(html).toMatch(/Section One/)
    expect(html).toMatch(/Section Two/)
    jest.useRealTimers()
  })

  // FOO-4485
  test.skip('it changes sections', () => {
    view.$el.find('button').click()
    $('input[value=2]').parent().click()
    expect(view.currentSection).toBe('2')
  })

  // FOO-4485
  test.skip('it publishes changes', done => {
    expect.assertions(1)
    $.subscribe('currentSection/change', section => {
      expect(section).toBe('2')
      done()
    })
    view.$el.find('button').click()
    $('input[value=2]').parent().click()
    $.unsubscribe('currentSection/change')
  })
})
