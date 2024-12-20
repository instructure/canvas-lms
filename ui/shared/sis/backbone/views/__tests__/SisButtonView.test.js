/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import Backbone from '@canvas/backbone'
import SisButtonView from '../SisButtonView'
import '@canvas/jquery/jquery.ajaxJSON'

// Mock jQuery extensions
$.flashWarning = jest.fn()
$.ajaxJSON = jest.fn()

class AssignmentStub extends Backbone.Model {
  constructor() {
    super(...arguments)
    this.postToSIS = this.postToSIS.bind(this)
    this.name = this.name.bind(this)
    this.dueAt = this.dueAt.bind(this)
    this.allDates = this.allDates.bind(this)
  }

  postToSIS(postToSisBoolean) {
    if (!(arguments.length > 0)) {
      return this.get('post_to_sis')
    }
    return this.set('post_to_sis', postToSisBoolean)
  }

  name(newName) {
    if (!(arguments.length > 0)) {
      return this.get('name')
    }
    return this.set('name', newName)
  }

  maxNameLength() {
    return ENV.MAX_NAME_LENGTH
  }

  dueAt(date) {
    if (!(arguments.length > 0)) {
      return this.get('due_at')
    }
    return this.set('due_at', date)
  }

  allDates(alldate) {
    if (!(arguments.length > 0)) {
      return this.get('all_dates')
    }
    return this.set('all_dates', alldate)
  }

  sisIntegrationSettingsEnabled() {
    return ENV.SIS_INTEGRATION_SETTINGS_ENABLED
  }
}
AssignmentStub.prototype.url = '/fake'

class QuizStub extends Backbone.Model {
  constructor() {
    super(...arguments)
    this.postToSIS = this.postToSIS.bind(this)
    this.name = this.name.bind(this)
    this.dueAt = this.dueAt.bind(this)
    this.allDates = this.allDates.bind(this)
  }

  postToSIS(postToSisBoolean) {
    if (!(arguments.length > 0)) {
      return this.get('post_to_sis')
    }
    return this.set('post_to_sis', postToSisBoolean)
  }

  name(newName) {
    if (!(arguments.length > 0)) {
      return this.get('title')
    }
    return this.set('title', newName)
  }

  maxNameLength() {
    return ENV.MAX_NAME_LENGTH
  }

  dueAt(date) {
    if (!(arguments.length > 0)) {
      return this.get('due_at')
    }
    return this.set('due_at', date)
  }

  allDates(alldate) {
    if (!(arguments.length > 0)) {
      return this.get('all_dates')
    }
    return this.set('all_dates', alldate)
  }

  sisIntegrationSettingsEnabled() {
    return ENV.SIS_INTEGRATION_SETTINGS_ENABLED
  }
}
QuizStub.prototype.url = '/fake'

describe('SisButtonView', () => {
  let assignment
  let quiz
  let view
  let ajaxStub

  beforeEach(() => {
    assignment = new AssignmentStub({id: 1})
    quiz = new QuizStub({id: 1, assignment_id: 2})
    $.flashWarning.mockClear()
    $.ajaxJSON.mockClear()
  })

  afterEach(() => {
    view?.$el.remove()
    jest.clearAllMocks()
  })

  it('properly populates initial settings', () => {
    assignment.set('post_to_sis', true)
    quiz.set('post_to_sis', false)
    const view1 = new SisButtonView({model: assignment, sisName: 'SIS'})
    const view2 = new SisButtonView({model: quiz, sisName: 'SIS'})
    view1.render()
    view2.render()
    expect(view1.$input.attr('title')).toBe('Sync to SIS enabled. Click to toggle.')
    expect(view2.$input.attr('title')).toBe('Sync to SIS disabled. Click to toggle.')
  })

  it('properly populates initial settings with custom SIS name', () => {
    assignment.set('post_to_sis', true)
    quiz.set('post_to_sis', false)
    const view1 = new SisButtonView({model: assignment, sisName: 'PowerSchool'})
    const view2 = new SisButtonView({model: quiz, sisName: 'PowerSchool'})
    view1.render()
    view2.render()
    expect(view1.$input.attr('title')).toBe('Sync to PowerSchool enabled. Click to toggle.')
    expect(view2.$input.attr('title')).toBe('Sync to PowerSchool disabled. Click to toggle.')
  })

  it('properly toggles model sis status when clicked', () => {
    ENV.MAX_NAME_LENGTH = 256
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    view = new SisButtonView({model: assignment})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeTruthy()
    view.$el.click()
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('does not save if there are name length errors for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    view = new SisButtonView({model: assignment, maxNameLengthRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('saves if there are name length errors for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is false', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    view = new SisButtonView({model: assignment, maxNameLengthRequired: false})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeTruthy()
  })

  it('does not save if there are name length errors for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    view = new SisButtonView({model: quiz, maxNameLengthRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeFalsy()
  })

  it('saves if there are name length errors for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is false', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    view = new SisButtonView({model: quiz, maxNameLengthRequired: false})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeTruthy()
  })

  it('does not save if there are due date errors for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    view = new SisButtonView({model: assignment, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('saves if there are overrides but not base due date for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    assignment.set('all_dates', [{dueAt: 'Test'}, {dueAt: 'Test2'}])
    assignment.set('due_at', null)
    view = new SisButtonView({model: assignment, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeTruthy()
  })

  it('does not save if there are no due date overrides and no base due date for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    assignment.set('all_dates', [])
    assignment.set('due_at', null)
    view = new SisButtonView({model: assignment, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('does not save if there is only one due date override and no base due date for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    assignment.set('all_dates', [
      {dueAt: 'Test', dueFor: 'section_1'},
      {dueAt: null, dueFor: 'section_2'},
    ])
    assignment.set('due_at', null)
    view = new SisButtonView({model: assignment, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('does not save if there are no due dates on overrides assignment and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    assignment.set('all_dates', [{dueAt: null}, {dueAt: null}])
    assignment.set('due_at', 'I am a date')
    view = new SisButtonView({model: assignment, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('saves if there are overrides but not base due date for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    quiz.set('all_dates', [{dueAt: 'Test'}, {dueAt: 'Test2'}])
    quiz.set('due_at', null)
    view = new SisButtonView({model: quiz, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeTruthy()
  })

  it('does not save if there are no due date overrides and no base due date for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    quiz.set('all_dates', [])
    quiz.set('due_at', null)
    view = new SisButtonView({model: quiz, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeFalsy()
  })

  it('does not save if there is only one due date override and no base due date for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    quiz.set('all_dates', [
      {dueAt: 'Test', dueFor: 'section_1'},
      {dueAt: null, dueFor: 'section_2'},
    ])
    quiz.set('due_at', null)
    view = new SisButtonView({model: quiz, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeFalsy()
  })

  it('saves if there are no due date overrides and base for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    quiz.set('all_dates', [{dueAt: null}, {dueAt: null}])
    quiz.set('due_at', 'I am a date')
    view = new SisButtonView({model: quiz, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeFalsy()
  })

  it('saves if there are due date errors for assignment and SIS_INTEGRATION_SETTINGS_ENABLED is false', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    assignment.set('post_to_sis', false)
    assignment.set('name', 'Too Much Tuna')
    view = new SisButtonView({model: assignment, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(assignment.postToSIS()).toBeTruthy()
  })

  it('does not save if there are due date errors for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is true', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    view = new SisButtonView({model: quiz, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeFalsy()
  })

  it('saves if there are due date errors for quiz and SIS_INTEGRATION_SETTINGS_ENABLED is false', () => {
    ENV.MAX_NAME_LENGTH = 5
    ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
    quiz.set('post_to_sis', false)
    quiz.set('title', 'Too Much Tuna')
    view = new SisButtonView({model: quiz, dueDateRequired: true})
    view.render()
    view.$el.click()
    expect(quiz.postToSIS()).toBeTruthy()
  })

  it('toggles post_to_sis for an assignment', () => {
    ENV.MAX_NAME_LENGTH = 256
    ENV.COURSE_ID = 1001
    assignment.set('name', 'Gil Faizon')
    assignment.set('post_to_sis', true)
    view = new SisButtonView({model: assignment})
    view.render()
    view.$el.click()
    expect($.ajaxJSON.mock.calls[0].slice(0, 3)).toEqual([
      '/api/v1/courses/1001/assignments/1',
      'PUT',
      {
        assignment: {override_dates: false, post_to_sis: false},
      },
    ])
    expect(assignment.postToSIS()).toBeFalsy()
  })

  it('toggles post_to_sis for a quiz', () => {
    ENV.MAX_NAME_LENGTH = 256
    ENV.COURSE_ID = 1001
    quiz.set('title', 'George St. Geegland')
    quiz.set('post_to_sis', false)
    view = new SisButtonView({model: quiz})
    view.render()
    view.$el.click()
    expect($.ajaxJSON.mock.calls[0].slice(0, 3)).toEqual([
      '/api/v1/courses/1001/assignments/2',
      'PUT',
      {
        assignment: {override_dates: false, post_to_sis: true},
      },
    ])
    expect(quiz.postToSIS()).toBeTruthy()
  })

  it('properly associates button label via aria-describedby', () => {
    assignment.set('id', '1')
    view = new SisButtonView({model: assignment})
    view.render()
    expect(view.$input.attr('aria-describedby')).toBe('sis-status-label-1')
    expect(view.$label.attr('id')).toBe('sis-status-label-1')
  })

  it('properly toggles aria-pressed value based on post_to_sis', () => {
    assignment.set('post_to_sis', true)
    view = new SisButtonView({model: assignment})
    view.render()
    expect(view.$label.attr('aria-pressed')).toBe('true')
    $.ajaxJSON.mockImplementation((url, method, data, success) => success(data.assignment))
    view.$el.click()
    expect(view.$label.attr('aria-pressed')).toBe('false')
  })
})
