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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {AccessibilityIssue, FormType} from '../../types'

interface Props {
  issue: AccessibilityIssue
  issueFormState: Map<string, string>
  setIssueFormState: React.Dispatch<React.SetStateAction<Map<string, string>>>
  handleFormChange: (issue: AccessibilityIssue, formValue: string) => void
}

const AccessibilityIssueForm: React.FC<Props> = ({
  issue,
  issueFormState,
  setIssueFormState,
  handleFormChange,
}: Props) => {
  switch (issue.form.type) {
    case FormType.Checkbox:
      return (
        <View as="div" margin="small 0" data-testid="checkbox-form">
          <Checkbox
            label={issue.form.label}
            checked={issueFormState.get(issue.id) === 'true'}
            onChange={() => {
              const newState = new Map(issueFormState)
              newState.set(issue.id, newState.get(issue.id) === 'true' ? 'false' : 'true')
              setIssueFormState(newState)
              handleFormChange(issue, newState.get(issue.id) || 'false')
            }}
          />
        </View>
      )
    case FormType.ColorPicker:
      return (
        <View as="div" margin="small 0">
          <Text weight="bold">{issue.form.label}</Text>
        </View>
      )
    case FormType.TextInput:
      return (
        <View as="div" margin="small 0" data-testid="text-input-form">
          <Text weight="bold">{issue.form.label}</Text>
          <View as="div" margin="x-small 0 0 0">
            <TextInput
              display="inline-block"
              width="15rem"
              value={issueFormState.get(issue.id) || ''}
              onChange={(_, value) => {
                const newState = new Map(issueFormState)
                newState.set(issue.id, value)
                setIssueFormState(newState)
                handleFormChange(issue, value)
              }}
            />
          </View>
        </View>
      )
    case FormType.DropDown:
      return (
        <SimpleSelect
          renderLabel={issue.form.label}
          value={issueFormState.get(issue.id) || ''}
          onChange={(_, {id, value}) => {
            const newState = new Map(issueFormState)
            if (value && typeof value === 'string') {
              newState.set(issue.id, value)
            }
            setIssueFormState(newState)
            handleFormChange(issue, value as string)
          }}
        >
          {issue.form.options?.map((option, index) => (
            <SimpleSelect.Option
              id={option}
              key={index}
              value={option}
              selected={issue.form.value === option}
              disabled={issue.form.value !== option}
            >
              {option}
            </SimpleSelect.Option>
          )) || <></>}
        </SimpleSelect>
      )
    default:
      return <></>
  }
}

export default AccessibilityIssueForm
