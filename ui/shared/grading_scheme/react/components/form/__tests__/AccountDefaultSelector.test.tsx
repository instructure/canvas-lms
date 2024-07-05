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

import React from 'react'
import {render} from '@testing-library/react'
import {AccountDefaultSelector, type AccountDefaultSelectorProps} from '../AccountDefaultSelector'
import {AccountGradingSchemes} from '../../__tests__/fixtures'

describe('AccountDefaultSelector tests', () => {
  const renderAccountDefaultSelector = (props: Partial<AccountDefaultSelectorProps> = {}) => {
    return render(
      <AccountDefaultSelector
        defaultGradingSchemeId="0"
        gradingSchemes={AccountGradingSchemes}
        onChange={() => {}}
        {...props}
      />
    )
  }

  it('apply/applied button is not shown initially', () => {
    const {queryByText} = renderAccountDefaultSelector()
    expect(queryByText('Apply')).not.toBeInTheDocument()
    expect(queryByText('Applied')).not.toBeInTheDocument()
  })

  it('apply button appears when you switch to an unselected grading scheme', () => {
    const {getByText, getByTestId} = renderAccountDefaultSelector()
    const select = getByTestId('account-default-grading-scheme-select')
    select.click()
    const option = getByTestId('grading-scheme-1-option')
    option.click()
    expect(getByText('Apply')).toBeInTheDocument()
  })

  it('apply button text changes to applied after default grading scheme changes', () => {
    const {getByText, getByTestId} = renderAccountDefaultSelector()
    const select = getByTestId('account-default-grading-scheme-select')
    select.click()
    const option = getByTestId('grading-scheme-1-option')
    option.click()
    const apply = getByText('Apply')
    apply.click()
    expect(getByText('Applied')).toBeInTheDocument()
  })

  it('reselecting the current default changes the apply text to applied', () => {
    const {getByText, getByTestId} = renderAccountDefaultSelector()
    const select = getByTestId('account-default-grading-scheme-select')
    select.click()
    const option = getByTestId('grading-scheme-1-option')
    option.click()
    expect(getByText('Apply')).toBeInTheDocument()
    select.click()
    const current = getByTestId('grading-scheme-0-option')
    current.click()
    expect(getByText('Applied')).toBeInTheDocument()
  })
})
