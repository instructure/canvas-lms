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

import CheckboxCollection from '../../collections/ContentCheckboxCollection'
import CheckboxView from '../ContentCheckboxView'
import CheckboxModel from '../../models/ContentCheckbox'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import sinon from 'sinon'
import '@canvas/jquery/jquery.disableWhileLoading'

const fixturesDiv = document.createElement('div')
fixturesDiv.id = 'fixtures'
document.body.appendChild(fixturesDiv)

class CheckboxHelper {
  static initClass() {
    this.$fixtures = $('#fixtures')
    this.checkboxView = undefined
    this.$sublevelCheckboxes = scope => {
      let $boxes = this.checkboxView.$el.find('.collectionViewItems').last().find('[type=checkbox]')
      if (scope) {
        $boxes = $boxes.filter(scope)
      }
      return $boxes
    }
  }

  static renderView(options) {
    if (!options) {
      options = {}
    }
    const checkboxModel = new CheckboxModel(options)
    if (!checkboxModel.property) {
      checkboxModel.property = 'copy[all_assignments]'
    }
    if (!checkboxModel.title) {
      checkboxModel.title = 'Assignments'
    }
    if (!checkboxModel.type) {
      checkboxModel.type = 'assignments'
    }
    new CheckboxCollection([checkboxModel], {isTopLevel: true})
    this.checkboxView = new CheckboxView({model: checkboxModel})
    return this.$fixtures.html(this.checkboxView.render().el)
  }

  static teardown() {
    return this.checkboxView.remove()
  }

  static $checkbox() {
    return this.$fixtures.find('[type=checkbox]').first()
  }

  static $carrot() {
    return this.$fixtures.find('.checkbox-carrot').first()
  }

  static serverResponse() {
    return [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify([
        {
          type: 'assignment_groups',
          property: 'copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]',
          title: 'Assignments',
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
      ]),
    ]
  }
}
CheckboxHelper.initClass()

describe('Content Checkbox Behaviors', () => {
  afterEach(() => {
    CheckboxHelper.teardown()
  })

  test('renders a checkbox with name set from model property', () => {
    CheckboxHelper.renderView({property: 'copy[all_assignments]'})
    const nameValue = CheckboxHelper.$checkbox().prop('name')
    expect(nameValue).toBe('copy[all_assignments]')
  })
})

describe('#getIconClass', () => {
  afterEach(() => {
    CheckboxHelper.teardown()
  })

  test('returns lti icon class for tool profiles', () => {
    CheckboxHelper.renderView()
    CheckboxHelper.checkboxView.model.set({type: 'tool_profiles'})
    expect(CheckboxHelper.checkboxView.getIconClass()).toBe('icon-lti')
  })
})

describe('Sublevel Content Checkbox and Carrot Behaviors', () => {
  let server
  const url = '/api/v1/courses/42/content_migrations/5/selective_data?type=assignments'

  beforeEach(() => {
    fakeENV.setup()
    server = sinon.fakeServer.create()
    server.respondWith('GET', url, CheckboxHelper.serverResponse())
    CheckboxHelper.renderView({sub_items_url: url})
    CheckboxHelper.checkboxView.$el.trigger('fetchCheckboxes')
    server.respond()
    CheckboxHelper.checkboxView.$el.find("[data-state='closed']").show()
  })

  afterEach(() => {
    fakeENV.teardown()
    server.restore()
    CheckboxHelper.teardown()
  })

  test('renders sublevel checkboxes', () => {
    expect(CheckboxHelper.$sublevelCheckboxes().length).toBe(3)
  })

  test('checkboxes with sublevel checkboxes and no url only display labels', () => {
    expect(
      CheckboxHelper.checkboxView.$el.find('label[title=Assignments]').siblings('[type=checkbox]')
        .length
    ).toBe(0)
  })
})
