/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {updateModuleItem} from '../../jquery/utils'
import ContextModulesPublishIcon from '../ContextModulesPublishIcon'
import {initBody, makeModuleWithItems} from '../../__tests__/testHelpers'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/context-modules/jquery/utils', () => {
  const originalModule = jest.requireActual('@canvas/context-modules/jquery/utils')
  return {
    __esmodule: true,
    ...originalModule,
    updateModuleItem: jest.fn(),
  }
})

const defaultProps = {
  courseId: '1',
  moduleId: '1',
  moduleName: 'Lesson 2',
  published: true,
  isPublishing: false,
}

const PUBLISH_URL = '/api/v1/courses/1/modules/1'

beforeEach(() => {
  doFetchApi.mockResolvedValue({response: {ok: true}, json: {published: true}})
  initBody()
  makeModuleWithItems(1, 'Lesson 2', [117, 119])
})

afterEach(() => {
  jest.clearAllMocks()
  doFetchApi.mockReset()
  document.body.innerHTML = ''
})

describe('ContextModulesPublishIcon', () => {
  describe('basic rendering', () => {
    it('displays a spinner with default message while publishing is in-flight', () => {
      const {getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} isPublishing={true} />
      )
      expect(getByText('working')).toBeInTheDocument()
    })

    it('displays a spinner with given message while publishing is in-flight', () => {
      const {getByText} = render(
        <ContextModulesPublishIcon
          {...defaultProps}
          isPublishing={true}
          loadingMessage="the loading message"
        />
      )
      expect(getByText('the loading message')).toBeInTheDocument()
    })

    it('renders as unpublished when unpublished', () => {
      const {container, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={false} />
      )
      expect(getByText('Lesson 2 module publish options, unpublished')).toBeInTheDocument()
      expect(container.querySelector('[name="IconUnpublished"]')).toBeInTheDocument()
    })

    it('renders as published when published', () => {
      const {container, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={true} />
      )
      expect(getByText('Lesson 2 module publish options, published')).toBeInTheDocument()
      expect(container.querySelector('[name="IconPublish"]')).toBeInTheDocument()
    })
  })

  it('renders the menu when clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    expect(getByText('Publish module and all items')).toBeInTheDocument()
    expect(getByText('Publish module only')).toBeInTheDocument()
    expect(getByText('Unpublish module and all items')).toBeInTheDocument()
    expect(getByText('Unpublish module only')).toBeInTheDocument()
  })

  it('calls publishAll when clicked publish all menu item is clicked', async () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Lesson 2 module publish options, published'})
    act(() => menuButton.click())
    const publishButton = getByText('Publish module and all items')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Publishing module and items')).toBeInTheDocument())
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'PUT',
        path: PUBLISH_URL,
        body: {module: {published: true, skip_content_tags: false}},
      })
    )
    expect(getByText('Module and items published')).toBeInTheDocument()
  })

  it('calls publishModuleOnly when clicked publish module menu item is clicked', async () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Lesson 2 module publish options, published'})
    act(() => menuButton.click())
    const publishButton = getByText('Publish module only')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Publishing module')).toBeInTheDocument())
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'PUT',
        path: PUBLISH_URL,
        body: {module: {published: true, skip_content_tags: true}},
      })
    )
    expect(getByText('Module published')).toBeInTheDocument()
  })

  it('calls unpublishAll when clicked unpublish all items is clicked', async () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Lesson 2 module publish options, published'})
    act(() => menuButton.click())
    const publishButton = getByText('Unpublish module and all items')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Unpublishing module and items')).toBeInTheDocument())
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'PUT',
        path: PUBLISH_URL,
        body: {module: {published: false, skip_content_tags: false}},
      })
    )
    expect(getByText('Module and items unpublished')).toBeInTheDocument()
  })

  it('calls unpublishModuleOnly when unpublish module only is clicked', async () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Lesson 2 module publish options, published'})
    act(() => menuButton.click())
    const publishButton = getByText('Unpublish module only')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Unpublishing module')).toBeInTheDocument())
    expect(doFetchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'PUT',
        path: PUBLISH_URL,
        body: {module: {published: false, skip_content_tags: true}},
      })
    )
    expect(getByText('Module unpublished')).toBeInTheDocument()
  })

  it('calls updateModuleItem when publishing', async () => {
    const fetchPromise = new Promise(resolve => {
      const {getByRole, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={false} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Publish module and all items')
      act(() => publishButton.click())
      waitFor(() => {
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_17: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object)
        )
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_19: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object)
        )
      })
      resolve({response: {ok: true}, json: {published: true}})
    })
    doFetchApi.mockReturnValue(fetchPromise)
    await fetchPromise
    waitFor(() => {
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_17: expect.any(Object)}),
        {bulkPublishInFlight: false, published: true},
        expect.any(Object)
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_19: expect.any(Object)}),
        {bulkPublishInFlight: false, published: true},
        expect.any(Object)
      )
    })
  })

  it('calls updateModuleItem when unpublishing', async () => {
    const fetchPromise = new Promise(resolve => {
      const {getByRole, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={true} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Unpublish module and all items')
      act(() => publishButton.click())
      waitFor(() => {
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_17: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object)
        )
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_19: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object)
        )
      })
      resolve({response: {ok: true}, json: {published: false}})
    })
    doFetchApi.mockReturnValue(fetchPromise)
    await fetchPromise
    waitFor(() => {
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_17: expect.any(Object)}),
        {bulkPublishInFlight: false, published: false},
        expect.any(Object)
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_19: expect.any(Object)}),
        {bulkPublishInFlight: false, published: false},
        expect.any(Object)
      )
    })
  })

  it('disables the Publish All menu button when publishing or unpublishing', async () => {
    // ts is inferring what window.modules should look like. I don't care about anything else.
    // @ts-expect-error
    window.modules = {
      updatePublishMenuDisabledState: jest.fn(),
    }

    const fetchPromise = new Promise(resolve => {
      const {getByRole, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={true} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Unpublish module and all items')
      act(() => publishButton.click())
      waitFor(() => {
        expect(window.modules.updatePublishMenuDisabledState).toHaveBeenCalledWith(true)
      })
      resolve({response: {ok: true}, json: {published: false}})
    })
    doFetchApi.mockReturnValue(fetchPromise)
    await fetchPromise
    waitFor(() => {
      expect(window.modules.updatePublishMenuDisabledState).toHaveBeenCalledWith(false)
    })
  })
})
