/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import FeatureFlagAdminView from '@canvas/feature-flag-admin-view'
import FeatureFlagCollection from '@canvas/feature-flag-admin-view/backbone/collections/FeatureFlagCollection'
import FeatureFlag from '@canvas/feature-flag-admin-view/backbone/models/FeatureFlag.coffee'

let flags

QUnit.module('FeatureFlagAdminView', {
  setup() {
    window.ENV.context_asset_string = 'user_1'
    flags = [
      new FeatureFlag({
        feature: 'high_constrast',
        id: 'high_constrast',
        display_name: 'High Contrast',
        appliesTo: 'user',
        feature_flag: {
          feature: 'high_constrast',
          state: 'on',
          transitions: {
            on: {
              locked: false
            }
          }
        }
      }),
      new FeatureFlag({
        feature: 'underline_links',
        id: 'underline_links',
        display_name: 'Underline Links',
        appliesTo: 'user',
        feature_flag: {
          feature: 'underline_links',
          state: 'on',
          transitions: {
            on: {
              locked: false
            }
          }
        }
      }),
      new FeatureFlag({
        feature: 'new_user_tutorial_on_off',
        id: 'new_user_tutorial_on_off',
        display_name: 'New User Tutorials',
        appliesTo: 'user',
        feature_flag: {
          feature: 'new_user_tutorial_on_off',
          state: 'on',
          transitions: {
            on: {
              locked: false
            }
          }
        }
      })
    ]
  }
})

test('it does not render feature flags that are passed in via the hiddenFlags option', () => {
  const hiddenFlags = ['new_user_tutorial_on_off']

  const view = new FeatureFlagAdminView({
    el: '#fixtures',
    hiddenFlags
  })

  view.collection = new FeatureFlagCollection(flags)
  view.render()
  equal($('li.feature-flag').length, 2)
  equal($('.new_user_tutorial_on_off').length, 0)
})

test('it renders all feature flags if you do not pass a hiddenFlags option', () => {
  const view = new FeatureFlagAdminView({el: '#fixtures'})

  view.collection = new FeatureFlagCollection(flags)
  view.render()
  equal($('li.feature-flag').length, 3)
})
