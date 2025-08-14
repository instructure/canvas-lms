/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {ContentItem, ContentItemType, FormType} from '../../../../types'

// Base content item template for creating new items
const createBaseItem = (
  title: string,
  url: string,
  editUrl: string,
): Omit<ContentItem, 'issues'> => ({
  id: Math.floor(Math.random() * 1000),
  title,
  type: ContentItemType.WikiPage,
  url,
  editUrl,
  published: true,
  updatedAt: '2024-07-01T00:00:00Z',
  count: 1,
})

// Button Rule Mock
export const buttonRuleItem: ContentItem = {
  ...createBaseItem(
    'Button Rule Test Page',
    'http://test.com/button-page',
    'http://test.com/button-page/edit',
  ),
  issues: [
    {
      id: 'button-issue-1',
      path: '/html/body/div[1]',
      ruleId: 'button-rule',
      displayName: 'Button Issue',
      message: 'This is a button issue that needs to be fixed',
      form: {
        type: FormType.Button,
        label: 'Apply',
      },
      why: 'Buttons should have proper accessibility attributes',
      element: '<button>Click me</button>',
    },
  ],
}

// Checkbox Text Input Rule Mock
export const checkboxTextInputRuleItem: ContentItem = {
  ...createBaseItem(
    'Checkbox Text Input Test Page',
    'http://test.com/checkbox-text-input-page',
    'http://test.com/checkbox-text-input-page/edit',
  ),
  issues: [
    {
      id: 'checkbox-text-input-issue-1',
      path: '/html/body/div[1]',
      ruleId: 'checkbox-text-input-rule',
      displayName: 'Checkbox Text Input Issue',
      message: 'This is a checkbox text input issue that needs to be fixed',
      form: {
        type: FormType.CheckboxTextInput,
        label: 'Text Input',
        checkboxLabel: 'Check this option',
        checkboxSubtext: 'Optional subtext',
        inputDescription: 'Input description',
        inputMaxLength: 100,
      },
      why: 'Checkbox text inputs should have proper labels and descriptions',
      element: '<input type="checkbox" /><input type="text" />',
    },
  ],
}

// Color Picker Rule Mock
export const colorPickerRuleItem: ContentItem = {
  ...createBaseItem(
    'Color Picker Test Page',
    'http://test.com/color-picker-page',
    'http://test.com/color-picker-page/edit',
  ),
  issues: [
    {
      id: 'color-picker-issue-1',
      path: '/html/body/div[1]',
      ruleId: 'color-picker-rule',
      displayName: 'Color Picker Issue',
      message: 'This is a color picker issue that needs to be fixed',
      form: {
        type: FormType.ColorPicker,
        label: 'Choose Color',
        backgroundColor: '#ffffff',
        contrastRatio: 4.5,
      },
      why: 'Color contrast should meet accessibility standards',
      element: '<div style="color: #000000; background-color: #ffffff;">Text</div>',
    },
  ],
}

// Radio Input Group Rule Mock
export const radioInputGroupRuleItem: ContentItem = {
  ...createBaseItem(
    'Radio Input Group Test Page',
    'http://test.com/radio-input-group-page',
    'http://test.com/radio-input-group-page/edit',
  ),
  issues: [
    {
      id: 'radio-input-group-issue-1',
      path: '/html/body/div[1]',
      ruleId: 'radio-input-group-rule',
      displayName: 'Radio Input Group Issue',
      message: 'This is a radio input group issue that needs to be fixed',
      form: {
        type: FormType.RadioInputGroup,
        label: 'Choose one',
        options: ['Option 1', 'Option 2', 'Option 3'],
        value: 'Option 1',
      },
      why: 'Radio input groups should have proper labels and options',
      element:
        '<input type="radio" name="group" value="1" /><input type="radio" name="group" value="2" />',
    },
  ],
}

// Text Input Rule Mock
export const textInputRuleItem: ContentItem = {
  ...createBaseItem(
    'Text Input Test Page',
    'http://test.com/text-input-page',
    'http://test.com/text-input-page/edit',
  ),
  issues: [
    {
      id: 'text-input-issue-1',
      path: '/html/body/div[1]',
      ruleId: 'text-input-rule',
      displayName: 'Text Input Issue',
      message: 'This is a text input issue that needs to be fixed',
      form: {
        type: FormType.TextInput,
        label: 'Enter text',
        value: 'Default value',
      },
      why: 'Text inputs should have proper labels and values',
      element: '<input type="text" value="default" />',
    },
  ],
}

// Multi-issue item (unique to this file)
export const multiIssueItem: ContentItem = {
  ...createBaseItem(
    'Multi Issue Test Page',
    'http://test.com/multi-issue-page',
    'http://test.com/multi-issue-page/edit',
  ),
  count: 2,
  issues: [
    {
      id: 'issue-1',
      path: '/html/body/div[1]',
      ruleId: 'adjacent-links',
      displayName: 'Adjacent links',
      message: 'This is a test issue',
      form: {
        type: FormType.Button,
        label: 'Apply',
      },
      why: '',
      element: '',
    },
    {
      id: 'issue-2',
      path: '/html/body/div[2]',
      ruleId: 'headings-sequence',
      displayName: 'Heading sequence',
      message: 'Second issue',
      form: {
        type: FormType.RadioInputGroup,
        label: 'Choose one',
        options: ['One', 'Two'],
        value: 'One',
      },
      why: '',
      element: '',
    },
  ],
}
