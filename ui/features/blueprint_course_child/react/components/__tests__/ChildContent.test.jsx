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
import {shallow} from 'enzyme'
import ChildContent from '../ChildContent'
import getSampleData from '@canvas/blueprint-courses/getSampleData'

describe('ChildContent app', () => {
  const defaultProps = () => ({
    isChangeLogOpen: false,
    terms: getSampleData().terms,
    childCourse: getSampleData().childCourse,
    masterCourse: getSampleData().masterCourse,
    realRef: () => {},
    routeTo: () => {},
    selectChangeLog: () => {},
  })

  test('renders the ChildContent component', () => {
    const tree = shallow(<ChildContent {...defaultProps()} />)
    const node = tree.find('.bcc__wrapper')
    expect(node.exists()).toBeTruthy()
  })

  test('clearRoutes removes blueprint path', () => {
    const props = defaultProps()
    props.routeTo = jest.fn()
    const tree = shallow(<ChildContent {...props} />)
    const instance = tree.instance()
    instance.clearRoutes()
    expect(props.routeTo).toHaveBeenCalledWith('#!/blueprint')
  })

  test('showChangeLog calls selectChangeLog prop with argument', () => {
    const props = defaultProps()
    props.selectChangeLog = jest.fn()
    const tree = shallow(<ChildContent {...props} />)
    const instance = tree.instance()
    instance.showChangeLog('5')
    expect(props.selectChangeLog).toHaveBeenCalledWith('5')
  })

  test('hideChangeLog calls selectChangeLog prop with null', () => {
    const props = defaultProps()
    props.selectChangeLog = jest.fn()
    const tree = shallow(<ChildContent {...props} />)
    const instance = tree.instance()
    instance.hideChangeLog()
    expect(props.selectChangeLog).toHaveBeenCalledWith(null)
  })

  test('realRef gets called with component instance on mount', () => {
    const props = defaultProps()
    props.realRef = jest.fn()
    const ref = React.createRef()
    const tree = render(<ChildContent {...props} ref={ref} />)
    const instance = ref.current
    expect(props.realRef).toHaveBeenCalledTimes(1)
    expect(props.realRef).toHaveBeenCalledWith(instance)
  })
})
