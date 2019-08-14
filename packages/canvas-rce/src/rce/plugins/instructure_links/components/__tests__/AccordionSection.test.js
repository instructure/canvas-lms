/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import AccordionSection from '../AccordionSection'

function renderComponent(props) {
  return render(
    <AccordionSection
      collection="assignments"
      onToggle={() => {}}
      expanded={false}
      label="Assignments"
      {...props}
    >
      the children
    </AccordionSection>
  )
}

describe('RCE "Links" Plugin > AccordionSection', () => {
  it('renders closed', () => {
    const {getByText, queryByText} = renderComponent()

    expect(getByText('Assignments')).toBeInTheDocument()
    expect(getByText('Expand to see Assignments')).toBeInTheDocument()
    expect(queryByText('the children')).toBeNull()
  })

  it('renders open', () => {
    const {getByText} = renderComponent({expanded: true})

    expect(getByText('Assignments')).toBeInTheDocument()
    expect(getByText('Collapse to hide Assignments')).toBeInTheDocument()
    expect(getByText('the children')).toBeInTheDocument()
  })

  it('calls onToggle when toggling', () => {
    const onToggle = jest.fn()
    const {getByText} = renderComponent({onToggle})

    const expandBtn = getByText('Expand to see Assignments')
    expandBtn.click()

    expect(onToggle).toHaveBeenCalledWith('assignments')
  })
})
