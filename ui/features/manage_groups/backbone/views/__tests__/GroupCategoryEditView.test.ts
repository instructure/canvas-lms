/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory'
import GroupCategoryEditView from '@canvas/groups/backbone/views/GroupCategoryEditView'
import fakeENV from '@canvas/test-utils/fakeENV'
import {isAccessible} from '@canvas/test-utils/assertions'

// @ts-expect-error - Legacy Backbone typing
let view = null
// @ts-expect-error - Legacy Backbone typing
let groupCategory = null
// @ts-expect-error - Legacy Backbone typing
let $fixtures

// @ts-expect-error - Legacy Backbone typing
const equal = (value, expected) => expect(value).toEqual(expected)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const selfSignupEndDateContainer = document.createElement('div')
selfSignupEndDateContainer.setAttribute('id', 'self_signup_end_at_picker')
document.body.appendChild(selfSignupEndDateContainer)

describe('GroupCategoryEditView', () => {
  beforeEach(() => {
    fakeENV.setup({allow_self_signup: true})
    // @ts-expect-error TS7 migration
    groupCategory = new GroupCategory()
    // @ts-expect-error TS7 migration
    view = new GroupCategoryEditView({model: groupCategory})
    view.render()
    $fixtures = $('#fixtures')
    view.$el.appendTo($('#fixtures'))
  })

  afterEach(() => {
    fakeENV.teardown()
    // @ts-expect-error - Legacy Backbone typing
    view.remove()
    // @ts-expect-error - Legacy Backbone typing
    document.getElementById('fixtures').innerHTML = ''
  })

  test('it should be accessible', async () => {
    // @ts-expect-error - Legacy Backbone typing
    await isAccessible($fixtures, {a11yReport: true})
  })

  test('validateFormData does not error when group_limit is null', () => {
    const data = {
      name: 'Valid Group Name',
      group_limit: null,
      self_signup: 0,
    }
    // @ts-expect-error - Legacy Backbone typing
    const errors = view.validateFormData(data, {})

    expect(errors.group_limit).toBeUndefined()
  })

  test('auto leadership is unset without model state', () => {
    // @ts-expect-error - Legacy Backbone typing
    groupCategory.set('auto_leader', null)
    // @ts-expect-error - Legacy Backbone typing
    view.setAutoLeadershipFormState()
    // @ts-expect-error - Legacy Backbone typing
    equal(view.$autoGroupLeaderToggle.prop('checked'), false)
  })

  test('auto leadership corresponds to model state', () => {
    // @ts-expect-error - Legacy Backbone typing
    groupCategory.set('auto_leader', 'random')
    // @ts-expect-error - Legacy Backbone typing
    view.setAutoLeadershipFormState()
    // @ts-expect-error - Legacy Backbone typing
    equal(view.$autoGroupLeaderToggle.prop('checked'), true)
    // @ts-expect-error - Legacy Backbone typing
    equal(view.$autoGroupLeaderControls.find("input[value='RANDOM']").prop('checked'), true)
    // @ts-expect-error - Legacy Backbone typing
    equal(view.$autoGroupLeaderControls.find("input[value='FIRST']").prop('checked'), false)
  })

  test('renders correct description based on ENV.self_signup_deadline_enabled', () => {
    // Test when self_signup_deadline_enabled is true
    fakeENV.setup({allow_self_signup: true, self_signup_deadline_enabled: true})
    // @ts-expect-error - Legacy Backbone typing
    view = new GroupCategoryEditView({model: groupCategory})
    view.render()

    const descriptionWithDeadline =
      'You can create sets of groups where students can sign up on their own. Students are still limited to being in only one group in the set, but this way students can organize themselves into groups instead of needing the teacher to do the work. With this option enabled, students can move themselves from one group to another. However, you can set an end date to close self sign-up to prevent students from joining or changing groups after a certain date.'
    expect(view.$('.icon-question').attr('title').trim()).toEqual(descriptionWithDeadline)

    view.remove()
    // @ts-expect-error - Legacy Backbone typing
    document.getElementById('fixtures').innerHTML = ''

    // Test when self_signup_deadline_enabled is false
    fakeENV.setup({allow_self_signup: true, self_signup_deadline_enabled: false})
    // @ts-expect-error - Legacy Backbone typing
    view = new GroupCategoryEditView({model: groupCategory})
    view.render()

    const descriptionWithoutDeadline =
      'You can create sets of groups where students can sign up on their own. Students are still limited to being in only one group in the set, but this way students can organize themselves into groups instead of needing the teacher to do the work. With this option enabled, students can move themselves from one group to another. Note that as long as this option is enabled, students can move themselves from one group to another.'
    expect(view.$('.icon-question').attr('title').trim()).toEqual(descriptionWithoutDeadline)

    fakeENV.teardown()
  })
})
