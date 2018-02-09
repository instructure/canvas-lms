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

import React from 'react'
import ThemeEditor from 'jsx/theme_editor/ThemeEditor'
import {shallow} from 'enzyme'

QUnit.module('Theme Editor')

test('when something has changed it puts tabIndex=-1 and aria-hidden on the preview frame', () => {
  const props = {
    brandConfig: {
      md5: '9e3c6d00c73e0fa989896e63077b45a8',
      variables: {}
    },
    hasUnsavedChanges: true,
    variableSchema: [],
    accountID: '1'
  }
  sessionStorage.setItem(
    'sharedBrandConfigBeingEdited',
    JSON.stringify({
      brand_config: {md5: '9e3c6d00c73e0fa989896e63077b45aa', variables: {}},
      name: 'Fake'
    })
  )
  const wrapper = shallow(<ThemeEditor {...props} />)
  wrapper.instance().changeSomething('bgColor', '#fff', false)
  const iframe = wrapper.find('#previewIframe')
  ok(iframe.prop('aria-hidden'))
  equal(iframe.prop('tabIndex'), '-1')
})

let testProps
QUnit.module('Theme Editor Theme Store', {
  setup: () => {
    testProps = {
      brandConfig: {
        md5: '9e3c6d00c73e0fa989896e63077b45a8',
        variables: {
          'ic-brand-primary': 'green',
          'ic-brand-global-nav-ic-icon-svg-fill': '#efefef'
        }
      },
      hasUnsavedChanges: true,
      variableSchema: [
        {
          group_key: 'global_branding',
          variables: [
            {
              variable_name: 'ic-brand-primary',
              type: 'color',
              default: '#008EE2',
              human_name: 'Primary Brand Color'
            },
            {
              variable_name: 'ic-brand-font-color-dark',
              type: 'color',
              default: '#2D3B45',
              human_name: 'Main Text Color'
            }
          ],
          group_name: 'Global Branding'
        },
        {
          group_key: 'global_navigation',
          variables: [
            {
              variable_name: 'ic-brand-global-nav-bgd',
              type: 'color',
              default: '#394B58',
              human_name: 'Nav Background'
            },
            {
              variable_name: 'ic-brand-global-nav-ic-icon-svg-fill',
              type: 'color',
              default: '#ffffff',
              human_name: 'Nav Icon'
            }
          ],
          group_name: 'Global Navigation'
        }
      ],
      accountID: '1'
    }
    sessionStorage.setItem(
      'sharedBrandConfigBeingEdited',
      JSON.stringify({
        brand_config: {md5: '9e3c6d00c73e0fa989896e63077b45aa', variables: {}},
        name: 'Fake'
      })
    )
  },
  teardown: () => {
    testProps = null
  }
})

test('constructor sets the theme store state properly using variableSchema and brandConfig props', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': '#2D3B45',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef'
    },
    files: []
  })
})

test('handleThemeStateChange updates theme store', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  wrapper.instance().handleThemeStateChange('ic-brand-font-color-dark', 'black')
  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': 'black',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef'
    },
    files: []
  })
})
