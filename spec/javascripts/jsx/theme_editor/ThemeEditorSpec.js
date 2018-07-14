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
import {fromPairs} from 'lodash'

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

const getDefaultFileList = () => {
  const KEYS = ['js_overrides', 'css_overrides', 'mobile_js_overrides', 'mobile_css_overrides'];
  return KEYS.map(x => ({
    customFileUpload: true,
    variable_name: x,
    value: undefined
  }))
}

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
        },
        {
          group_key: 'watermarks',
          variables: [
            {
              variable_name: 'ic-brand-favicon',
              type: 'image',
              accept: 'image/vnd.microsoft.icon,image/x-icon,image/png,image/gif',
              default: '/images/favicon.ico',
              human_name: 'Favicon',
              helper_text: 'You can use a single 16x16, 32x32, 48x48 ico file.'
            }
          ]
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
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: getDefaultFileList()
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
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: getDefaultFileList()
  })
})

test('handleThemeStateChange updates when there is a file', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  const key = 'ic-brand-favicon'
  const value = new File(['foo'], 'foo.png')
  wrapper.instance().handleThemeStateChange(key, value)

  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': '#2D3B45',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: [
      ...getDefaultFileList(),
      {
        value,
        variable_name: key
      }
    ]
  })
})

test('handleThemeStateChange sets the file object to have the customFileUpload flag when there is a customFileUpload', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  const key = 'custom_css'
  const value = new File(['foo'], 'foo.png')
  wrapper.instance().handleThemeStateChange(key, value, {customFileUpload: true})
  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': '#2D3B45',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: [
      ...getDefaultFileList(),
      {
        value,
        variable_name: key,
        customFileUpload: true
      }
    ]
  })
})

test('handleThemeStateChange resets to default when opts.resetValue is set', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  wrapper.instance().handleThemeStateChange('ic-brand-font-color-dark', 'black')

  wrapper.instance().handleThemeStateChange('ic-brand-font-color-dark', null, {resetValue: true})
  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': '#2D3B45',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: getDefaultFileList()
  })
})

test('handleThemeStateChange sets values to original default values when opts.useDefault is set', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  wrapper.instance().handleThemeStateChange('ic-brand-favicon', '/path/to/some/image.ico')

  wrapper.instance().handleThemeStateChange('ic-brand-favicon', null, {resetValue: true, useDefault: true})
  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': '#2D3B45',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: getDefaultFileList()
  })
})

test('handleThemeStateChange sets file objects in the store to their previous value when opts.resetValue is set', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  const key = 'ic-brand-favicon'
  const value = new File(['foo'], 'foo.png')
  wrapper.instance().handleThemeStateChange(key, value)

  wrapper.instance().handleThemeStateChange(key, null, {resetValue: true})
  deepEqual(wrapper.state('themeStore'), {
    properties: {
      'ic-brand-primary': 'green',
      'ic-brand-font-color-dark': '#2D3B45',
      'ic-brand-global-nav-bgd': '#394B58',
      'ic-brand-global-nav-ic-icon-svg-fill': '#efefef',
      'ic-brand-favicon': '/images/favicon.ico'
    },
    files: [
      ...getDefaultFileList(),
      {
        value: undefined,
        variable_name: "ic-brand-favicon"
      }
    ]
  })
})


test('processThemeStoreForSubmit puts the themeStore into a FormData and returns it', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  const fileValue = new File(['foo'], 'foo.png')
  wrapper.instance().handleThemeStateChange('ic-brand-favicon', fileValue)
  wrapper.instance().handleThemeStateChange('ic-brand-font-color-dark', 'black')
  wrapper.instance().changeSomething('ic-brand-font-color-dark', 'black', false)
  const formData = wrapper.instance().processThemeStoreForSubmit()
  const formObj = fromPairs(Array.from(formData.entries()))
  deepEqual(formObj, {
    'brand_config[variables][ic-brand-font-color-dark]': 'black',
    'brand_config[variables][ic-brand-global-nav-ic-icon-svg-fill]': '#efefef',
    'brand_config[variables][ic-brand-primary]': 'green',
    'brand_config[variables][ic-brand-favicon]': fileValue,
    'css_overrides': '',
    'js_overrides': '',
    'mobile_css_overrides': '',
    'mobile_js_overrides': ''
  })
})

test('processThemeStoreForSubmit sets the correct keys for custom uploads', () => {
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  const key = 'css_overrides'
  const value = new File(['foo'], 'foo.png')
  wrapper.instance().handleThemeStateChange(key, value, {customFileUpload: true})
  const formData = wrapper.instance().processThemeStoreForSubmit()
  const formObj = fromPairs(Array.from(formData.entries()))
  deepEqual(formObj, {
    'brand_config[variables][ic-brand-global-nav-ic-icon-svg-fill]': '#efefef',
    'brand_config[variables][ic-brand-primary]': 'green',
    'js_overrides': '',
    'mobile_css_overrides': '',
    'mobile_js_overrides': '',
    [key]: value
  })
});

test('processThemeStoreForSubmit sets the correct keys for custom uploads that already have values', () => {
  testProps.brandConfig.js_overrides = '/some/path/to/a/file'
  const wrapper = shallow(<ThemeEditor {...testProps} />)
  const key = 'css_overrides'
  const value = new File(['foo'], 'foo.png')
  wrapper.instance().handleThemeStateChange(key, value, {customFileUpload: true})
  const formData = wrapper.instance().processThemeStoreForSubmit()
  const formObj = fromPairs(Array.from(formData.entries()))
  deepEqual(formObj, {
    'brand_config[variables][ic-brand-global-nav-ic-icon-svg-fill]': '#efefef',
    'brand_config[variables][ic-brand-primary]': 'green',
    'js_overrides': '/some/path/to/a/file',
    'mobile_css_overrides': '',
    'mobile_js_overrides': '',
    [key]: value
  })
})
