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
import {shallow, mount} from 'enzyme'
import sinon from 'sinon'
import FileUpload from '../FileUpload'
import Folder from '@canvas/files/backbone/models/Folder'
import {merge} from 'lodash'

describe('FileUpload', () => {
  let sandbox
  beforeAll(() => {
    sinon.spy(document, 'addEventListener')
  })

  beforeEach(() => {
    sandbox = sinon.createSandbox()
  })

  afterEach(() => {
    sandbox.restore()
  })

  const defaultProps = (props = {}) => {
    const ref = document.createElement('div')
    return merge(
      {
        filesDirectoryRef: ref,
        currentFolder: new Folder(),
      },
      props
    )
  }

  it('renders the FileUpload component', () => {
    const component = shallow(<FileUpload {...defaultProps()} />)
    expect(component.exists()).toBe(true)
  })

  it('sets isDragging to false when a file has been dropped', () => {
    const wrapper = shallow(<FileUpload {...defaultProps()} />)
    wrapper.instance().setState({isDragging: true})
    wrapper.instance().handleDrop([], [{file: 'foo'}], {})
    expect(wrapper.instance().state.isDragging).toEqual(false)
  })

  it('renders a FileDrop when there are no files', () => {
    const props = defaultProps()
    sandbox.stub(props.currentFolder, 'isEmpty').returns(true)
    const wrapper = mount(<FileUpload {...props} />)
    expect(wrapper.find('Billboard')).toHaveLength(2)
    expect(wrapper.find('FileDrop')).toHaveLength(3)
    expect(wrapper.find('.FileUpload__full')).toHaveLength(1)
  })

  it('renders fileDrop when isDragging is true', () => {
    const wrapper = shallow(<FileUpload {...defaultProps()} />)
    wrapper.instance().setState({isDragging: true})
    expect(wrapper.find('.FileUpload__dragging')).toHaveLength(1)
  })

  it('does not render a full sized FileDrop when the currentFolder is not empty', () => {
    const props = defaultProps()
    sandbox.stub(props.currentFolder, 'isEmpty').returns(false)
    const wrapper = shallow(<FileUpload {...props} />)
    expect(wrapper.find('.FileUpload__full')).toHaveLength(0)
  })
})
