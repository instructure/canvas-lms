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
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import EditHeaderView from '../EditHeaderView'
import editViewTemplate from '../../../jst/EditView.handlebars'
import Backbone from '@canvas/backbone'
import axe from 'axe-core'
import {assignLocation} from '@canvas/util/globalUtils'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

const createEditHeaderView = (
  assignmentOptions = {},
  viewOptions = {},
  beforeRender,
  defaultAssignmentOpts = {
    name: 'Test Assignment',
    assignment_overrides: [],
  },
) => {
  Object.assign(assignmentOptions, defaultAssignmentOpts)
  const assignment = new Assignment(assignmentOptions)
  const app = new EditHeaderView({
    model: assignment,
    views: {edit_assignment_form: new Backbone.View({template: editViewTemplate})},
    userIsAdmin: viewOptions.userIsAdmin,
  })
  if (beforeRender) beforeRender(app)
  return app.render()
}

describe('EditHeaderView', () => {
  let container

  beforeEach(() => {
    fakeENV.setup({
      current_user_roles: ['teacher'],
      current_user_is_admin: false,
      FEATURES: {
        instui_nav: true,
      },
      SETTINGS: {},
    })
    container = document.createElement('div')
    container.id = 'fixtures'
    container.setAttribute('role', 'main')
    container.setAttribute('aria-label', 'Assignment Edit')
    document.body.appendChild(container)
    $(document).on('submit', e => e.preventDefault())
  })

  afterEach(() => {
    fakeENV.teardown()
    container.remove()
    $(document).off('submit')
    jest.resetAllMocks()
    jest.clearAllMocks()
  })

  // TODO: Fix accessibility test - requires more complex DOM setup
  it.skip('is accessible', async () => {
    const view = createEditHeaderView()
    view.$el.appendTo(container)

    // Add proper semantic structure
    const header = document.createElement('header')
    header.setAttribute('role', 'banner')
    container.insertBefore(header, container.firstChild)
    view.$('.assignment-edit-header').appendTo(header)

    const main = document.createElement('main')
    main.setAttribute('role', 'main')
    main.setAttribute('aria-label', 'Assignment Edit Form')
    container.appendChild(main)
    view.$('form').appendTo(main)

    const results = await axe.run(container, {
      rules: {
        'color-contrast': {enabled: false},
      },
      runOnly: ['wcag2a', 'wcag2aa'],
    })
    expect(results.violations).toHaveLength(0)
  })

  it('renders header bar', () => {
    const view = createEditHeaderView()
    expect(view.$('.assignment-edit-header')).toHaveLength(1)
  })

  describe('header titles', () => {
    it('shows "Create New Assignment" for new non-LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {})
      expect(view.$('.assignment-edit-header-title').text()).toBe('Create New Assignment')
      expect(view.$('.screenreader-only').text()).toContain('Create New Assignment')
    })

    it('shows "Create Quiz" for new LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {is_quiz_lti_assignment: true})
      expect(view.$('.assignment-edit-header-title').text()).toBe('Create Quiz')
      expect(view.$('.screenreader-only').text()).toContain('Create Quiz')
    })

    it('shows "Edit Quiz" for existing LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {
        name: 'Hello World',
        is_quiz_lti_assignment: true,
      })
      expect(view.$('.assignment-edit-header-title').text()).toBe('Edit Quiz')
    })

    it('shows "Edit Assignment" for existing non-LTI quiz assignments', () => {
      const view = createEditHeaderView()
      expect(view.$('.assignment-edit-header-title').text()).toBe('Edit Assignment')
    })
  })

  describe('publish status', () => {
    it('shows "Not Published" for unpublished non-LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {
        name: 'Hello World',
        published: false,
      })
      expect(view.$('.published-assignment-container').text()).toBe('Not Published')
    })

    it('shows "Published" for published non-LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {
        name: 'Hello World',
        published: true,
      })
      expect(view.$('.published-assignment-container').text()).toBe('Published')
    })

    it('shows "Not Published" for unpublished LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {
        name: 'Hello World',
        is_quiz_lti_assignment: true,
        published: false,
      })
      expect(view.$('.published-assignment-container').text()).toBe('Not Published')
    })

    it('shows "Published" for published LTI quiz assignments', () => {
      const view = createEditHeaderView({}, {}, false, {
        name: 'Hello World',
        is_quiz_lti_assignment: true,
        published: true,
      })
      expect(view.$('.published-assignment-container').text()).toBe('Published')
    })
  })

  describe('delete functionality', () => {
    it('calls onDeleteSuccess for unsaved assignments', () => {
      fakeENV.setup({ASSIGNMENT_INDEX_URL: '/assignments', SETTINGS: {}})
      const view = createEditHeaderView()
      const onDeleteSuccess = jest.spyOn(view, 'onDeleteSuccess')
      view.delete()
      expect(onDeleteSuccess).toHaveBeenCalled()
      expect(assignLocation).toHaveBeenCalledWith('/assignments')
      fakeENV.teardown()
    })

    it('disables delete for frozen assignments', () => {
      const view = createEditHeaderView({frozen: true})
      expect(view.$('.delete_assignment_link.disabled')).toHaveLength(1)
    })

    it('disables delete for assignments in closed grading periods', () => {
      const view = createEditHeaderView({in_closed_grading_period: true})
      expect(view.$('.delete_assignment_link.disabled')).toHaveLength(1)
    })

    it('enables delete for non-frozen assignments not in closed grading periods', () => {
      const view = createEditHeaderView({
        frozen: false,
        in_closed_grading_period: false,
      })
      expect(view.$('.delete_assignment_link:not(.disabled)')).toHaveLength(1)
    })

    it('enables delete for frozen assignments when user is admin', () => {
      const view = createEditHeaderView({frozen: true}, {userIsAdmin: true})
      expect(view.$('.delete_assignment_link:not(.disabled)')).toHaveLength(1)
    })

    it('enables delete for assignments in closed grading periods when user is admin', () => {
      const view = createEditHeaderView({in_closed_grading_period: true}, {userIsAdmin: true})
      expect(view.$('.delete_assignment_link:not(.disabled)')).toHaveLength(1)
    })

    it('prevents delete for assignments in closed grading periods', () => {
      const view = createEditHeaderView({in_closed_grading_period: true})
      jest.spyOn(window, 'confirm')
      jest.spyOn(view, 'delete')
      view.$('.delete_assignment_link').click()
      expect(window.confirm).not.toHaveBeenCalled()
      expect(view.delete).not.toHaveBeenCalled()
    })
  })

  describe('SpeedGrader link', () => {
    beforeEach(() => {
      fakeENV.setup({SHOW_SPEED_GRADER_LINK: true, SETTINGS: {}})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('shows when assignment is published', () => {
      const view = createEditHeaderView({published: true})
      expect(view.$('.speed-grader-link-container')).toHaveLength(1)
    })
  })
})
