/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import Steps from '../index'
import StepItem from '../StepItem/index'

describe('Steps', () => {
  it('should render', () => {
    const container = render(<Steps />)
    expect(container.getByTestId('assignment-2-step-index')).toBeInTheDocument()
  })

  it('should not render collapsed class when not collapsed', () => {
    const container = render(<Steps isCollapsed={false} />)
    expect(container.queryByTestId('steps-container-collapsed')).not.toBeInTheDocument()
  })

  it('should render collapsed class when collapsed', () => {
    const container = render(<Steps isCollapsed={true} />)
    expect(container.getByTestId('steps-container-collapsed')).toBeInTheDocument()
  })

  it('should render with StepItems', () => {
    const container = render(
      <Steps label="Settings">
        <StepItem label="Phase one" status="complete" />
        <StepItem label="Phase two" status="in-progress" />
        <StepItem label="Phase three" />
      </Steps>
    )
    expect(container.getByText('Phase one')).toBeInTheDocument()
    expect(container.getByText('Phase two')).toBeInTheDocument()
    expect(container.getByText('Phase three')).toBeInTheDocument()
  })

  it('should render aria-current for the item that is in progress', async () => {
    const container = render(
      <Steps label="Settings">
        <StepItem label="Phase one" status="complete" />
        <StepItem label="Phase two" status="in-progress" />
        <StepItem label="Phase three" />
      </Steps>
    )

    const items = container.getAllByRole('listitem')
    expect(items[0].getAttribute('aria-current')).toEqual('false')
    expect(items[1].getAttribute('aria-current')).toEqual('true')
    expect(items[2].getAttribute('aria-current')).toEqual('false')
  })
})
