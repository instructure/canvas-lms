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
import FileUpload from '../FileUpload'
import Folder from '@canvas/files/backbone/models/Folder'
import {merge} from 'lodash'

describe('FileUpload', () => {
  let addEventListenerSpy

  beforeAll(() => {
    addEventListenerSpy = jest.spyOn(document, 'addEventListener')
  })

  afterAll(() => {
    addEventListenerSpy.mockRestore()
  })

  const defaultProps = (props = {}) => {
    const ref = document.createElement('div')
    return merge(
      {
        filesDirectoryRef: ref,
        currentFolder: new Folder(),
      },
      props,
    )
  }

  it('renders the FileUpload component', () => {
    const ref = React.createRef()
    render(<FileUpload {...defaultProps()} ref={ref} />)
    expect(ref.current).not.toBeNull()
  })

  it('sets isDragging to false when a file has been dropped', () => {
    const ref = React.createRef()
    render(<FileUpload {...defaultProps()} ref={ref} />)
    ref.current.setState({isDragging: true})
    ref.current.handleDrop([], [{file: 'foo'}], {})
    expect(ref.current.state.isDragging).toEqual(false)
  })

  it('renders a FileDrop when there are no files', () => {
    const props = defaultProps()
    jest.spyOn(props.currentFolder, 'isEmpty').mockReturnValue(true)
    const wrapper = render(<FileUpload {...props} />)
    // the Billboard
    expect(wrapper.getByText('Drop files here to upload')).toBeInTheDocument()
    // the FileDrop
    expect(wrapper.getByText('Drop files here to upload')).toBeInTheDocument()
    // the FileUpload
    expect(wrapper.getByTestId('fileUpload')).toBeInTheDocument()
  })

  it('renders fileDrop when isDragging is true', () => {
    const ref = React.createRef()
    const wrapper = render(<FileUpload {...defaultProps()} ref={ref} />)
    ref.current.setState({isDragging: true})
    expect(wrapper.container.querySelectorAll('.FileUpload__dragging')).toHaveLength(1)
  })

  it('does not render a full sized FileDrop when the currentFolder is not empty', () => {
    const props = defaultProps()
    jest.spyOn(props.currentFolder, 'isEmpty').mockReturnValue(false)
    const wrapper = render(<FileUpload {...props} />)
    expect(wrapper.container.querySelectorAll('.FileUpload__full')).toHaveLength(0)
  })
})
