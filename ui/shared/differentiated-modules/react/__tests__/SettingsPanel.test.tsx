/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import SettingsPanel, {SettingsPanelProps} from '../SettingsPanel'

describe('SettingsPanel', () => {
  const props: SettingsPanelProps = {
    moduleName: 'Week 1',
    unlockAt: '',
  }

  const renderComponent = (overrides = {}) => render(<SettingsPanel {...props} {...overrides} />)

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Module Name')).toBeInTheDocument()
  })

  it('renders the module name', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue('Week 1')).toBeInTheDocument()
  })

  it('renders the date time input when lock until is checked', () => {
    const {getByRole, getByText} = renderComponent()
    getByRole('checkbox').click()
    expect(getByText('Date')).toBeInTheDocument()
  })

  it('renders the date time input when unlockAt is set', () => {
    const {getByText} = renderComponent({unlockAt: '2020-01-01T00:00:00Z'})
    expect(getByText('Date')).toBeInTheDocument()
  })
})
