/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {defaultGradebookProps} from '../../__tests__/GradebookSpecHelper'
import {render, within} from '@testing-library/react'
import Gradebook from '../../Gradebook'
import '@testing-library/jest-dom/extend-expect'

describe('Gradebook', () => {
  it('GradebookMenu is rendered', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gradebookMenuNode={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook/i))
  })
})
