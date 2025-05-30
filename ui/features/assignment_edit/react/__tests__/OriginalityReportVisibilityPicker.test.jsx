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
import {render} from '@testing-library/react'
import OriginalityReportVisibilityPicker from '../OriginalityReportVisibilityPicker'

describe('OriginalityReportVisibilityPicker', () => {
  test('it renders', () => {
    const {getByRole} = render(
      <OriginalityReportVisibilityPicker isEnabled={true} selectedOption="immediate" />,
    )
    expect(getByRole('combobox')).toBeInTheDocument()
  })

  const options = ['immediate', 'after_grading', 'after_due_date', 'never']
  options.forEach(option => {
    test(`it renders "${option}" option`, () => {
      const {container} = render(
        <OriginalityReportVisibilityPicker isEnabled={true} selectedOption="immediate" />,
      )
      expect(container.querySelector(`option[value='${option}']`)).toBeInTheDocument()
    })
  })

  test('it selects the "selectedOption"', () => {
    const {getByDisplayValue} = render(
      <OriginalityReportVisibilityPicker isEnabled={true} selectedOption="after_due_date" />,
    )
    expect(getByDisplayValue('After the due date')).toBeInTheDocument()
  })
})
