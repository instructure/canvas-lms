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

import axios from '@canvas/axios'
import React from 'react'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DefaultToolForm from '../DefaultToolForm'
import * as SelectContentDialog from '@canvas/select-content-dialog'

const renderComponent = (props = {}) => {
  const defaultProps = {
    toolUrl: 'https://www.default-tool.com/blti',
    courseId: 1,
    toolName: 'Awesome Tool',
    previouslySelected: false,
  };
  return render(<DefaultToolForm {...defaultProps} {...props} />)
}


describe('DefaultToolForm', () => {
  beforeEach(() => {
    jest.spyOn(axios, 'get').mockResolvedValue({data: []})
  })

  it('renders a button to launch the tool', () => {
    const wrapper = renderComponent()
    expect(wrapper.getByRole('button', { name: 'Add Content' })).toBeInTheDocument()
  })

  it('launches the tool when the button is clicked', async () => {
    SelectContentDialog.Events.onContextExternalToolSelect = jest.fn()
    const wrapper = renderComponent()
    await userEvent.click(wrapper.getByRole('button', { name: 'Add Content' }))
    expect(SelectContentDialog.Events.onContextExternalToolSelect).toHaveBeenCalled()
    SelectContentDialog.Events.onContextExternalToolSelect.mockRestore()
  })

  it('renders the information message', () => {
    const wrapper = renderComponent()
    expect(wrapper.getByText('Click the button above to add content')).toBeInTheDocument()
  })

  it('sets the button text', () => {
    const wrapper = renderComponent({toolButtonText: 'Custom Button Text'})
    expect(wrapper.getByRole('button', { name: 'Custom Button Text' })).toBeInTheDocument()
  })

  it('renders the success message if previouslySelected is true', () => {
    const wrapper = renderComponent({previouslySelected: true})
    expect(wrapper.getByText('Successfully Added')).toBeInTheDocument()
  })

  describe('when the configured tool is not installed', () => {
    beforeEach(() => {
      axios.get.mockResolvedValue({
        data: [
          {
            placements: [
              {
                url: 'foo',
              },
            ],
          },
        ],
      })
    })

    it('renders an error message', async () => {
      const wrapper = renderComponent({previouslySelected: true})

      await waitFor(() => expect(wrapper.getByText('The tool is not installed in the course or account')).toBeInTheDocument())
    })
  })
})
