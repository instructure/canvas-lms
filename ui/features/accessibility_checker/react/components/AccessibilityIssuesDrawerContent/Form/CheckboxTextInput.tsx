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
import React, {useState, useEffect} from 'react'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {FormComponentProps} from '.'

const CheckboxTextInput = ({issue, value, onChangeValue}: FormComponentProps) => {
  const [isChecked, setChecked] = useState(false)

  useEffect(() => {
    if (isChecked && value) {
      onChangeValue('')
    }
  }, [isChecked])

  return (
    <>
      <View as="div">
        <Checkbox
          label={issue.form.checkboxLabel}
          checked={isChecked}
          onChange={() => setChecked(!isChecked)}
        />
      </View>
      <View as="div" margin="small 0 medium">
        <Text size="small" color="secondary">
          {issue.form.checkboxSubtext}
        </Text>
      </View>
      <View as="div" margin="small 0">
        <TextArea
          data-testid="checkbox-text-input-form"
          label={issue.form.label}
          disabled={isChecked}
          value={value || ''}
          onChange={e => onChangeValue(e.target.value)}
        />
      </View>
      <Flex as="div" justifyItems="space-between" margin="small 0">
        <Flex.Item>
          <Text size="small" color="secondary">
            {issue.form.inputDescription}
          </Text>
        </Flex.Item>
        <Flex.Item>
          <Text size="small" color="secondary">
            {value?.length || 0}/{issue.form.inputMaxLength}
          </Text>
        </Flex.Item>
      </Flex>
    </>
  )
}

export default CheckboxTextInput
