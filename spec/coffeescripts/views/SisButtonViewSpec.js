/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import SisButtonView from 'compiled/views/SisButtonView'
import Backbone from 'Backbone'


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

QUnit.module('SisButtonView', {
  setup() {
    this.assignment = new AssignmentStub()
    this.quiz = new QuizStub()
    this.quiz.set('toggle_post_to_sis_url', '/some_other_url')
  }
})

test('properly populates initial settings', function() {
  this.assignment.set('post_to_sis', true)
  this.quiz.set('post_to_sis', false)
  this.view1 = new SisButtonView({model: this.assignment, sisName: 'SIS'})
  this.view2 = new SisButtonView({model: this.quiz, sisName: 'SIS'})
  this.view1.render()
  this.view2.render()
  equal(this.view1.$input.attr('title'), 'Sync to SIS enabled. Click to toggle.')
  equal(this.view2.$input.attr('title'), 'Sync to SIS disabled. Click to toggle.')
})

test('properly populates initial settings with custom SIS name', function() {
  this.assignment.set('post_to_sis', true)
  this.quiz.set('post_to_sis', false)
  this.view1 = new SisButtonView({model: this.assignment, sisName: 'PowerSchool'})
  this.view2 = new SisButtonView({model: this.quiz, sisName: 'PowerSchool'})
  this.view1.render()
  this.view2.render()
  equal(this.view1.$input.attr('title'), 'Sync to PowerSchool enabled. Click to toggle.')
  equal(this.view2.$input.attr('title'), 'Sync to PowerSchool disabled. Click to toggle.')
})

test('properly toggles model sis status when clicked', function() {
  ENV.MAX_NAME_LENGTH = 256
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.assignment})
  this.view.render()
  this.view.$el.click()
  ok(this.assignment.postToSIS())
  this.view.$el.click()
  ok(!this.assignment.postToSIS())
})

test('model does not save if there are name length errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.assignment, maxNameLengthRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.assignment.postToSIS())
})

test('model saves if there are name length errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is false', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.assignment, maxNameLengthRequired: false})
  this.view.render()
  this.view.$el.click()
  ok(this.assignment.postToSIS())
})

test('model does not save if there are name length errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.quiz, maxNameLengthRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.quiz.postToSIS())
})

test('model saves if there are name length errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is false', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.quiz, maxNameLengthRequired: false})
  this.view.render()
  this.view.$el.click()
  ok(this.quiz.postToSIS())
})

test('model does not save if there are due date errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.assignment, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.assignment.postToSIS())
})

test('model saves if there are overrides but not base due date for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.assignment.set('all_dates', [{dueAt: 'Test'}, {dueAt: 'Test2'}])
  this.assignment.set('due_at', null)
  this.view = new SisButtonView({model: this.assignment, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(this.assignment.postToSIS())
})

test('model does not save if there are no due date overrides and no base due date for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.assignment.set('all_dates', [])
  this.assignment.set('due_at', null)
  this.view = new SisButtonView({model: this.assignment, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.assignment.postToSIS())
})

test('model does not save if there is only one due date override and no base due date for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.assignment.set('all_dates', [{dueAt: 'Test'}, {dueAt: null}])
  this.assignment.set('due_at', null)
  this.view = new SisButtonView({model: this.assignment, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.assignment.postToSIS())
})

test('model does not save if there are no due dates on overrides assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.assignment.set('all_dates', [{dueAt: null}, {dueAt: null}])
  this.assignment.set('due_at', 'I am a date')
  this.view = new SisButtonView({model: this.assignment, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.assignment.postToSIS())
})

test('model saves if there are overrides but not base due date for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.quiz.set('all_dates', [{dueAt: 'Test'}, {dueAt: 'Test2'}])
  this.quiz.set('due_at', null)
  this.view = new SisButtonView({model: this.quiz, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(this.quiz.postToSIS())
})

test('model does not save if there are no due date overrides and no base due date for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.quiz.set('all_dates', [])
  this.quiz.set('due_at', null)
  this.view = new SisButtonView({model: this.quiz, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.quiz.postToSIS())
})

test('model does not save if there is only one due date override and no base due date for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.quiz.set('all_dates', [{dueAt: 'Test'}, {dueAt: null}])
  this.quiz.set('due_at', null)
  this.view = new SisButtonView({model: this.quiz, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.quiz.postToSIS())
})

test('model saves if there are no due date overrides and base for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.quiz.set('all_dates', [{dueAt: null}, {dueAt: null}])
  this.quiz.set('due_at', 'I am a date')
  this.view = new SisButtonView({model: this.quiz, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.quiz.postToSIS())
})

test('model saves if there are due date errors for assignment AND SIS_INTEGRATION_SETTINGS_ENABLED is false', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
  this.assignment.set('post_to_sis', false)
  this.assignment.set('name', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.assignment, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(this.assignment.postToSIS())
})

test('model does not save if there are due date errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is true', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = true
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.quiz, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(!this.quiz.postToSIS())
})

test('model saves if there are due date errors for quiz AND SIS_INTEGRATION_SETTINGS_ENABLED is false', function() {
  ENV.MAX_NAME_LENGTH = 5
  ENV.SIS_INTEGRATION_SETTINGS_ENABLED = false
  this.quiz.set('post_to_sis', false)
  this.quiz.set('title', 'Too Much Tuna')
  this.view = new SisButtonView({model: this.quiz, dueDateRequired: true})
  this.view.render()
  this.view.$el.click()
  ok(this.quiz.postToSIS())
})

test('does not override dates', function() {
  ENV.MAX_NAME_LENGTH = 256
  this.assignment.set('name', 'Gil Faizon')
  const saveStub = sandbox.stub(this.assignment, 'save').callsFake(() => {})
  this.view = new SisButtonView({model: this.assignment})
  this.view.render()
  this.view.$el.click()
  ok(saveStub.calledWith({override_dates: false}))
})

test('properly saves model with a custom url if present', function() {
  ENV.MAX_NAME_LENGTH = 256
  this.quiz.set('title', 'George St. Geegland')
  sandbox.stub(this.quiz, 'save').callsFake(function(attributes, options) {
    ok(options.url, '/some_other_url')
  })
  this.quiz.set('post_to_sis', false)
  this.view = new SisButtonView({model: this.quiz})
  this.view.render()
  this.view.$el.click()
  ok(this.quiz.postToSIS())
})

test('properly associates button label via aria-describedby', function() {
  this.assignment.set('id', '1')
  this.view = new SisButtonView({model: this.assignment})
  this.view.render()
  equal(this.view.$input.attr('aria-describedby'), 'sis-status-label-1')
  equal(this.view.$label.attr('id'), 'sis-status-label-1')
})

test('properly toggles aria-pressed value based on post_to_sis', function() {
  this.assignment.set('post_to_sis', true)
  this.view = new SisButtonView({model: this.assignment})
  this.view.render()
  equal(this.view.$label.attr('aria-pressed'), 'true')
  this.view.$el.click()
  equal(this.view.$label.attr('aria-pressed'), 'false')
})
