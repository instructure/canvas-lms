/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import $ from 'jquery'
import PublishButton from '../PublishButton'
import * as apiClient from '@canvas/courses/courseAPIClient'
import {waitFor} from '@testing-library/dom'

jest.mock('@canvas/courses/courseAPIClient')

function createMockProps(opts = {}) {
  return {
    courseId: '0',
    pagesUrl: '',
    defaultView: 'modules',
    frontPageTitle: '',
    courseNickname: 'nickname',
    onSuccess: null,
    ...opts,
  }
}

describe('PublishButton', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.spyOn($, 'flashError').mockImplementation()
    apiClient.getModules.mockReturnValue(Promise.resolve({data: []}))
    expect.hasAssertions()
  })

  describe('when defaultView is modules', () => {
    it('fetches modules and renders the prompt if there are no modules', async () => {
      const wrapper = mount(<PublishButton {...createMockProps()} />)
      expect(wrapper.find('HomePagePromptContainer')).toHaveLength(0)
      apiClient.getModules.mockReturnValue(Promise.resolve({data: []}))
      await wrapper.find('button').simulate('click')
      expect(apiClient.getModules).toHaveBeenCalledWith({courseId: '0'})
      wrapper.update()
      expect(wrapper.instance().state.showModal).toBe(true)
      expect(wrapper.find('HomePagePromptContainer')).toHaveLength(1)
    })

    it('publishes when modules do exist', async () => {
      const wrapper = mount(<PublishButton {...createMockProps()} />)
      apiClient.getModules.mockReturnValue(Promise.resolve({data: ['module1']}))
      await wrapper.find('button').simulate('click')
      expect(apiClient.publishCourse).toHaveBeenCalledWith({courseId: '0', onSuccess: null})
    })

    it('publishes when modules do exist calling onSuccess callback', async () => {
      const onSuccess = jest.fn()
      const wrapper = mount(<PublishButton {...createMockProps({onSuccess})} />)
      apiClient.getModules.mockReturnValue(Promise.resolve({data: ['module1']}))
      await wrapper.find('button').simulate('click')
      expect(apiClient.publishCourse).toHaveBeenCalledWith({courseId: '0', onSuccess})
    })

    it('flashes an error when getModules fails', async () => {
      apiClient.getModules.mockRejectedValue(Promise.resolve())
      const wrapper = mount(<PublishButton {...createMockProps()} />)

      await wrapper.find('button').simulate('click')
      await waitFor(() => {
        expect($.flashError).toHaveBeenCalledWith(
          'An error ocurred while fetching course details. Please try again.'
        )
      })
    })
  })

  describe('when defaultView is not modules', () => {
    it('calls publishCourse immediately', () => {
      const wrapper = mount(<PublishButton {...createMockProps({defaultView: 'assignments'})} />)
      wrapper.find('button').simulate('click')
      expect(apiClient.getModules).not.toHaveBeenCalled()
      expect(apiClient.publishCourse).toHaveBeenCalledWith({courseId: '0', onSuccess: null})
    })

    it('calls publishCourse immediately with onSuccess callback', () => {
      const onSuccess = jest.fn()
      const wrapper = mount(
        <PublishButton {...createMockProps({defaultView: 'assignments', onSuccess})} />
      )
      wrapper.find('button').simulate('click')
      expect(apiClient.getModules).not.toHaveBeenCalled()
      expect(apiClient.publishCourse).toHaveBeenCalledWith({courseId: '0', onSuccess})
    })
  })

  it('renders SR content correctly', () => {
    const wrapper = mount(<PublishButton {...createMockProps({defaultView: 'assignments'})} />)
    const screenReaderNode = wrapper.find('ScreenReaderContent').first()
    expect(screenReaderNode.text()).toBe('nickname')
  })
})
