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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {ImageSection} from '../ImageSection'
import fetchMock from 'fetch-mock'
import FakeEditor from '../../../../../shared/__tests__/FakeEditor'
import svg from '../SingleColor/svg'

jest.mock('../../../../../shared/StoreContext', () => {
  return {
    ...jest.requireActual('../../../../../shared/StoreContext'),
    useStoreProps: () => ({
      images: {
        Course: {
          files: [
            {
              id: 722,
              filename: 'grid.png',
              thumbnail_url:
                'http://canvas.docker/images/thumbnails/722/E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b',
              display_name: 'image_one.png',
              href: 'http://canvas.docker/courses/21/files/722?wrap=1',
              download_url: 'http://canvas.docker/files/722/download?download_frd=1',
              content_type: 'image/png',
              published: true,
              hidden_to_user: true,
              locked_for_user: false,
              unlock_at: null,
              lock_at: null,
              date: '2021-11-03T19:21:27Z',
              uuid: 'E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b'
            },
            {
              id: 716,
              filename: '1635371359_565__0266554465.jpeg',
              thumbnail_url:
                'http://canvas.docker/images/thumbnails/716/9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt',
              display_name: 'image_two.jpg',
              href: 'http://canvas.docker/courses/21/files/716?wrap=1',
              download_url: 'http://canvas.docker/files/716/download?download_frd=1',
              content_type: 'image/jpeg',
              published: true,
              hidden_to_user: false,
              locked_for_user: false,
              unlock_at: null,
              lock_at: null,
              date: '2021-10-27T21:49:19Z',
              uuid: '9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt'
            },
            {
              id: 715,
              filename: '1635371358_548__h3zmqPb-6dw.jpg',
              thumbnail_url:
                'http://canvas.docker/images/thumbnails/715/rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw',
              display_name: 'image_three.jpg',
              href: 'http://canvas.docker/courses/21/files/715?wrap=1',
              download_url: 'http://canvas.docker/files/715/download?download_frd=1',
              content_type: 'image/jpeg',
              published: true,
              hidden_to_user: false,
              locked_for_user: false,
              unlock_at: null,
              lock_at: null,
              date: '2021-10-27T21:49:18Z',
              uuid: 'rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw'
            }
          ],
          bookmark: 'bookmark',
          isLoading: false,
          hasMore: false
        }
      },
      contextType: 'Course',
      fetchInitialImages: jest.fn(),
      fetchNextImages: jest.fn()
    })
  }
})

jest.mock('../../../../../../../bridge', () => {
  return {
    trayProps: {
      get: () => ({foo: 'bar'})
    }
  }
})

describe('ImageSectionc', () => {
  const defaultProps = {
    settings: {},
    editing: false,
    editor: {},
    onChange: jest.fn()
  }

  const subject = overrides => render(<ImageSection {...{...defaultProps, ...overrides}} />)

  afterEach(() => jest.clearAllMocks())

  it('renders the image mode selector', () => {
    const {getByText} = subject()
    expect(getByText('Add Image')).toBeInTheDocument()
  })

  it('renders the image preview', () => {
    const {getByTestId} = subject()
    expect(getByTestId('selected-image-preview')).toBeInTheDocument()
  })

  it('sets default crop settings', () => {
    subject()

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetX',
      payload: '50%'
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetY',
      payload: '50%'
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetWidth',
      payload: 75
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetHeight',
      payload: 75
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetTranslateX',
      payload: -37.5
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetTranslateY',
      payload: -37.5
    })
  })

  describe('when the cropper FF is off', () => {
    let rendered

    beforeEach(() => {
      ENV.FEATURES.buttons_and_icons_cropper = false

      fetchMock.mock('/api/session', '{}')

      rendered = subject({editor: new FakeEditor()})
      fireEvent.click(rendered.getByText('Add Image'))
    })

    afterEach(() => fetchMock.restore())

    it('does not render the "Upload Image" button', () => {
      expect(rendered.queryByText('Upload Image')).not.toBeInTheDocument()
    })

    it('does not render the "Course Images" button', () => {
      expect(rendered.queryByText('Course Images')).not.toBeInTheDocument()
    })
  })

  describe('when no image is selected', () => {
    it('renders a "None Selected" message', () => {
      const {getByText} = subject()
      expect(getByText('None Selected')).toBeInTheDocument()
    })
  })

  describe('when the "upload image" mode is selected', () => {
    let rendered

    beforeEach(() => {
      ENV.FEATURES.buttons_and_icons_cropper = true

      fetchMock.mock('/api/session', '{}')

      rendered = subject({editor: new FakeEditor()})

      fireEvent.click(rendered.getByText('Add Image'))
      fireEvent.click(rendered.getByText('Upload Image'))
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('renders the image upload modal', async () => {
      await waitFor(() => expect(rendered.getByText('Upload Image')).toBeInTheDocument())
    })

    describe('and the the "close" button is clicked', () => {
      beforeEach(async () => {
        const button = await rendered.findAllByText(/Close/i)
        fireEvent.click(button[0])
      })

      it('closes the modal', () => {
        expect(rendered.queryByText('Upload Image')).toBe(null)
      })
    })
  })

  describe('when the "course images" mode is selected', () => {
    let getByTestId, getByText, getByTitle

    beforeEach(() => {
      ENV.FEATURES.buttons_and_icons_cropper = true

      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText
      getByTitle = rendered.getByTitle

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Course Images'))
    })

    it('renders the course images component', () => {
      expect(getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
    })

    describe('and an image is clicked', () => {
      let originalFileReader
      const flushPromises = () => new Promise(setImmediate)

      beforeEach(() => {
        fetchMock.mock('http://canvas.docker/files/722/download?download_frd=1', {})

        originalFileReader = FileReader
        Object.defineProperty(global, 'FileReader', {
          writable: true,
          value: jest.fn().mockImplementation(() => ({
            readAsDataURL() {
              this.onloadend()
            },
            result: 'data:image/png;base64,asdfasdfjksdf=='
          }))
        })

        // Click the first image
        fireEvent.click(getByTitle('Click to embed image_one.png'))
      })

      afterEach(() => {
        fetchMock.restore('http://canvas.docker/files/722/download?download_frd=1')
        Object.defineProperty(global, 'FileReader', {
          writable: true,
          value: originalFileReader
        })
      })

      it('dispatches an action to update parent state image', async () => {
        await flushPromises()
        expect(defaultProps.onChange).toHaveBeenCalledWith({
          type: 'SetEncodedImage',
          payload: 'data:image/png;base64,asdfasdfjksdf=='
        })
      })

      it('dispatches an action to update parent state image type', async () => {
        await flushPromises()
        expect(defaultProps.onChange).toHaveBeenCalledWith({
          type: 'SetEncodedImageType',
          payload: 'Course'
        })
      })

      it('dispatches an action to update parent state image name', async () => {
        await flushPromises()
        expect(defaultProps.onChange).toHaveBeenCalledWith({
          type: 'SetEncodedImageName',
          payload: 'grid.png'
        })
      })
    })
  })

  describe('when the "Multi Color Image" mode is selected', () => {
    let getByTestId, getByText

    beforeEach(() => {
      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Multi Color Image'))
    })

    it('renders the course images component', async () => {
      await waitFor(() => expect(getByTestId('multicolor-svg-list')).toBeInTheDocument())
    })
  })

  describe('when the "Single Color Image" mode is selected', () => {
    let spyFn, getByTestId, getByText, container

    beforeAll(() => {
      spyFn = jest.spyOn(svg.art, 'source')
    })

    beforeEach(() => {
      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText
      container = rendered.container

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Single Color Image'))
    })

    it('renders the course images component', async () => {
      await waitFor(() => expect(getByTestId('singlecolor-svg-list')).toBeInTheDocument())
    })

    describe('user selects an image', () => {
      beforeEach(async () => {
        await waitFor(() => {
          expect(getByTestId('selected-image-preview')).toBeInTheDocument()
        })
        fireEvent.click(getByTestId('button-icon-art'))
      })

      it('sets default icon color', async () => {
        await waitFor(() => {
          expect(spyFn).toHaveBeenCalledWith('#111111')
          expect(getByTestId('selected-image-preview')).toHaveStyle(
            'backgroundImage: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgwIiBoZWlnaHQ9IjQ4MCIgdmlld0JveD0iMCAwIDQ4MCA0ODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgICAgIDxwYXRoIGQ9Ik0yNDAgMEMxMDcuNTUgMCAwIDEwNy41NSAwIDI0MEMwIDM3Mi41NTEgMTA3LjQ1NCA0ODAgMjQwIDQ4MEMyNDYuNDQ2IDQ4MCAyNTIuODMgNDc5Ljc0OSAyNTkuMTUyIDQ3OS4yNDhDMjg4LjU0NiA0NzYuOTI3IDMxMS4xNTggNDUyLjI3NSAzMTEuMTU4IDQyMi43OTJWMzU5LjgyQzMxMS4xNTggMzQ2LjkxNCAzMTYuMjg0IDMzNC41MzYgMzI1LjQxIDMyNS40MUMzMzQuNTM2IDMxNi4yODQgMzQ2LjkxNCAzMTEuMTU4IDM1OS44MiAzMTEuMTU4SDQyMy4zMTFDNDM3LjM5IDMxMS4xNjUgNDUwLjk1NiAzMDUuODc0IDQ2MS4zMTIgMjk2LjMzNkM0NzEuNjY4IDI4Ni43OTkgNDc4LjA1NiAyNzMuNzE0IDQ3OS4yMDUgMjU5LjY4MkM0NzkuNzM1IDI1My4xOTQgNDgwIDI0Ni42MzMgNDgwIDI0MEM0ODAgMTA3LjQ1NCAzNzIuNTUxIDAgMjQwIDBaTTkyLjYxNDYgMzA5LjAyOEM4NC43MzA2IDMxMC40OTQgNzYuNTg4OSAzMDkuNTg5IDY5LjIxOSAzMDYuNDI4QzYxLjg0OSAzMDMuMjY4IDU1LjU4MTYgMjk3Ljk5MyA1MS4yMDkyIDI5MS4yNzFDNDYuODM2NyAyODQuNTQ4IDQ0LjU1NTUgMjc2LjY4MSA0NC42NTQgMjY4LjY2MkM0NC43NTI0IDI2MC42NDQgNDcuMjI2MSAyNTIuODM0IDUxLjc2MjMgMjQ2LjIyMkM1Ni4yOTg1IDIzOS42MDkgNjIuNjkzNSAyMzQuNDg5IDcwLjEzODggMjMxLjUxMUM3Ny41ODQyIDIyOC41MzIgODUuNzQ1NSAyMjcuODI3IDkzLjU5MTIgMjI5LjQ4NkMxMDEuNDM3IDIzMS4xNDUgMTA4LjYxNCAyMzUuMDkzIDExNC4yMTcgMjQwLjgzMUMxMTkuODE5IDI0Ni41NjkgMTIzLjU5NCAyNTMuODM5IDEyNS4wNjUgMjYxLjcyMkMxMjYuMDQxIDI2Ni45NTkgMTI1Ljk3NyAyNzIuMzM3IDEyNC44NzQgMjc3LjU0OUMxMjMuNzcyIDI4Mi43NjEgMTIxLjY1MyAyODcuNzA0IDExOC42NCAyOTIuMDk3QzExNS42MjYgMjk2LjQ5IDExMS43NzcgMzAwLjI0NyAxMDcuMzExIDMwMy4xNTJDMTAyLjg0NiAzMDYuMDU3IDk3Ljg1MTkgMzA4LjA1MyA5Mi42MTQ2IDMwOS4wMjhaTTEwOS4xODcgMTI4LjAyNkMxMDcuNzE5IDEyMC4xNDIgMTA4LjYyMiAxMTEuOTk5IDExMS43ODIgMTA0LjYyN0MxMTQuOTQzIDk3LjI1NTUgMTIwLjIxOCA5MC45ODY2IDEyNi45NDEgODYuNjEzMkMxMzMuNjY0IDgyLjIzOTggMTQxLjUzMyA3OS45NTgyIDE0OS41NTIgODAuMDU3QzE1Ny41NzIgODAuMTU1OCAxNjUuMzgzIDgyLjYzMDYgMTcxLjk5NiA4Ny4xNjgzQzE3OC42MDkgOTEuNzA2MSAxODMuNzI4IDk4LjEwMyAxODYuNzA2IDEwNS41NUMxODkuNjgzIDExMi45OTcgMTkwLjM4NiAxMjEuMTYgMTg4LjcyNCAxMjkuMDA3QzE4Ny4wNjIgMTM2Ljg1MyAxODMuMTExIDE0NC4wMyAxNzcuMzcgMTQ5LjYzMUMxNzEuNjI5IDE1NS4yMzIgMTY0LjM1NyAxNTkuMDA0IDE1Ni40NzIgMTYwLjQ3MkMxNTEuMjM2IDE2MS40NDYgMTQ1Ljg2IDE2MS4zODEgMTQwLjY1MSAxNjAuMjc4QzEzNS40NDEgMTU5LjE3NSAxMzAuNSAxNTcuMDU2IDEyNi4xMDkgMTU0LjA0M0MxMjEuNzE4IDE1MS4wMyAxMTcuOTYzIDE0Ny4xODIgMTE1LjA2IDE0Mi43MThDMTEyLjE1NiAxMzguMjU0IDExMC4xNjEgMTMzLjI2MiAxMDkuMTg3IDEyOC4wMjZaTTIxNS43NzIgNDMyLjg0OEMyMDUuMjk0IDQzMi44NDggMTk1LjA1MSA0MjkuNzQgMTg2LjMzOCA0MjMuOTE5QzE3Ny42MjUgNDE4LjA5NyAxNzAuODM1IDQwOS44MjMgMTY2LjgyNSA0MDAuMTQyQzE2Mi44MTUgMzkwLjQ2MSAxNjEuNzY2IDM3OS44MDkgMTYzLjgxIDM2OS41MzJDMTY1Ljg1NCAzNTkuMjU0IDE3MC45IDM0OS44MTQgMTc4LjMxIDM0Mi40MDVDMTg1LjcxOSAzMzQuOTk2IDE5NS4xNTkgMzI5Ljk1IDIwNS40MzYgMzI3LjkwNUMyMTUuNzEzIDMyNS44NjEgMjI2LjM2NiAzMjYuOTEgMjM2LjA0NyAzMzAuOTJDMjQ1LjcyOCAzMzQuOTMgMjU0LjAwMiAzNDEuNzIxIDI1OS44MjQgMzUwLjQzM0MyNjUuNjQ1IDM1OS4xNDYgMjY4Ljc1MiAzNjkuMzg5IDI2OC43NTIgMzc5Ljg2OEMyNjguNzUyIDM5My45MTkgMjYzLjE3IDQwNy4zOTQgMjUzLjIzNSA0MTcuMzNDMjQzLjI5OSA0MjcuMjY2IDIyOS44MjMgNDMyLjg0OCAyMTUuNzcyIDQzMi44NDhaTTMxMy4xNjYgMTQ0LjI0NEMzMDUuMjgxIDE0NS43MSAyOTcuMTM4IDE0NC44MDYgMjg5Ljc2OCAxNDEuNjQ1QzI4Mi4zOTcgMTM4LjQ4NCAyNzYuMTI5IDEzMy4yMDkgMjcxLjc1NiAxMjYuNDg2QzI2Ny4zODQgMTE5Ljc2MyAyNjUuMTAzIDExMS44OTQgMjY1LjIwMiAxMDMuODc1QzI2NS4zMDEgOTUuODU1MyAyNjcuNzc2IDg4LjA0NTUgMjcyLjMxNCA4MS40MzI4QzI3Ni44NTIgNzQuODIgMjgzLjI0OCA2OS43MDEzIDI5MC42OTUgNjYuNzIzOEMyOTguMTQyIDYzLjc0NjMgMzA2LjMwNCA2My4wNDM4IDMxNC4xNSA2NC43MDUxQzMyMS45OTYgNjYuMzY2NCAzMjkuMTczIDcwLjMxNjkgMzM0Ljc3NCA3Ni4wNTdDMzQwLjM3NSA4MS43OTcyIDM0NC4xNDggODkuMDY5MiAzNDUuNjE2IDk2Ljk1MzZDMzQ3LjU4MyAxMDcuNTI4IDM0NS4yNyAxMTguNDUgMzM5LjE4NCAxMjcuMzE5QzMzMy4wOTkgMTM2LjE4OCAzMjMuNzQgMTQyLjI3NSAzMTMuMTY2IDE0NC4yNDRaTTQwNS45NiAyNjguNTU2QzM5OC4wNzUgMjcwLjAyNCAzODkuOTMyIDI2OS4xMjEgMzgyLjU2MSAyNjUuOTYxQzM3NS4xODkgMjYyLjgwMSAzNjguOTIgMjU3LjUyNSAzNjQuNTQ3IDI1MC44MDJDMzYwLjE3NCAyNDQuMDc5IDM1Ny44OTIgMjM2LjIxIDM1Ny45OTEgMjI4LjE5MUMzNTguMDkgMjIwLjE3MSAzNjAuNTY0IDIxMi4zNjEgMzY1LjEwMiAyMDUuNzQ3QzM2OS42NCAxOTkuMTM0IDM3Ni4wMzcgMTk0LjAxNSAzODMuNDg0IDE5MS4wMzdDMzkwLjkzMSAxODguMDYgMzk5LjA5NCAxODcuMzU3IDQwNi45NCAxODkuMDE5QzQxNC43ODcgMTkwLjY4MSA0MjEuOTY0IDE5NC42MzIgNDI3LjU2NSAyMDAuMzczQzQzMy4xNjUgMjA2LjExNCA0MzYuOTM4IDIxMy4zODcgNDM4LjQwNSAyMjEuMjcyQzQzOS4zOCAyMjYuNTA3IDQzOS4zMTQgMjMxLjg4MyA0MzguMjExIDIzNy4wOTJDNDM3LjEwOCAyNDIuMzAyIDQzNC45OSAyNDcuMjQzIDQzMS45NzcgMjUxLjYzNEM0MjguOTY0IDI1Ni4wMjUgNDI1LjExNiAyNTkuNzggNDIwLjY1MiAyNjIuNjgzQzQxNi4xODggMjY1LjU4NyA0MTEuMTk2IDI2Ny41ODIgNDA1Ljk2IDI2OC41NTZaIiBmaWxsPSIjMTExMTExIi8+CiAgICA8L3N2Zz4=))'
          )
        })
      })

      it('changes the icon color', async () => {
        await waitFor(() => {
          expect(container.querySelector('[name="single-color-image-fill"]')).toBeInTheDocument()
          fireEvent.change(container.querySelector('[name="single-color-image-fill"]'), {
            target: {value: '#00FF00'}
          })
        })
        await waitFor(() => {
          expect(spyFn).toHaveBeenCalledWith('#00FF00')
          expect(getByTestId('selected-image-preview')).toHaveStyle(
            'backgroundImage: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgwIiBoZWlnaHQ9IjQ4MCIgdmlld0JveD0iMCAwIDQ4MCA0ODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgICAgIDxwYXRoIGQ9Ik0yNDAgMEMxMDcuNTUgMCAwIDEwNy41NSAwIDI0MEMwIDM3Mi41NTEgMTA3LjQ1NCA0ODAgMjQwIDQ4MEMyNDYuNDQ2IDQ4MCAyNTIuODMgNDc5Ljc0OSAyNTkuMTUyIDQ3OS4yNDhDMjg4LjU0NiA0NzYuOTI3IDMxMS4xNTggNDUyLjI3NSAzMTEuMTU4IDQyMi43OTJWMzU5LjgyQzMxMS4xNTggMzQ2LjkxNCAzMTYuMjg0IDMzNC41MzYgMzI1LjQxIDMyNS40MUMzMzQuNTM2IDMxNi4yODQgMzQ2LjkxNCAzMTEuMTU4IDM1OS44MiAzMTEuMTU4SDQyMy4zMTFDNDM3LjM5IDMxMS4xNjUgNDUwLjk1NiAzMDUuODc0IDQ2MS4zMTIgMjk2LjMzNkM0NzEuNjY4IDI4Ni43OTkgNDc4LjA1NiAyNzMuNzE0IDQ3OS4yMDUgMjU5LjY4MkM0NzkuNzM1IDI1My4xOTQgNDgwIDI0Ni42MzMgNDgwIDI0MEM0ODAgMTA3LjQ1NCAzNzIuNTUxIDAgMjQwIDBaTTkyLjYxNDYgMzA5LjAyOEM4NC43MzA2IDMxMC40OTQgNzYuNTg4OSAzMDkuNTg5IDY5LjIxOSAzMDYuNDI4QzYxLjg0OSAzMDMuMjY4IDU1LjU4MTYgMjk3Ljk5MyA1MS4yMDkyIDI5MS4yNzFDNDYuODM2NyAyODQuNTQ4IDQ0LjU1NTUgMjc2LjY4MSA0NC42NTQgMjY4LjY2MkM0NC43NTI0IDI2MC42NDQgNDcuMjI2MSAyNTIuODM0IDUxLjc2MjMgMjQ2LjIyMkM1Ni4yOTg1IDIzOS42MDkgNjIuNjkzNSAyMzQuNDg5IDcwLjEzODggMjMxLjUxMUM3Ny41ODQyIDIyOC41MzIgODUuNzQ1NSAyMjcuODI3IDkzLjU5MTIgMjI5LjQ4NkMxMDEuNDM3IDIzMS4xNDUgMTA4LjYxNCAyMzUuMDkzIDExNC4yMTcgMjQwLjgzMUMxMTkuODE5IDI0Ni41NjkgMTIzLjU5NCAyNTMuODM5IDEyNS4wNjUgMjYxLjcyMkMxMjYuMDQxIDI2Ni45NTkgMTI1Ljk3NyAyNzIuMzM3IDEyNC44NzQgMjc3LjU0OUMxMjMuNzcyIDI4Mi43NjEgMTIxLjY1MyAyODcuNzA0IDExOC42NCAyOTIuMDk3QzExNS42MjYgMjk2LjQ5IDExMS43NzcgMzAwLjI0NyAxMDcuMzExIDMwMy4xNTJDMTAyLjg0NiAzMDYuMDU3IDk3Ljg1MTkgMzA4LjA1MyA5Mi42MTQ2IDMwOS4wMjhaTTEwOS4xODcgMTI4LjAyNkMxMDcuNzE5IDEyMC4xNDIgMTA4LjYyMiAxMTEuOTk5IDExMS43ODIgMTA0LjYyN0MxMTQuOTQzIDk3LjI1NTUgMTIwLjIxOCA5MC45ODY2IDEyNi45NDEgODYuNjEzMkMxMzMuNjY0IDgyLjIzOTggMTQxLjUzMyA3OS45NTgyIDE0OS41NTIgODAuMDU3QzE1Ny41NzIgODAuMTU1OCAxNjUuMzgzIDgyLjYzMDYgMTcxLjk5NiA4Ny4xNjgzQzE3OC42MDkgOTEuNzA2MSAxODMuNzI4IDk4LjEwMyAxODYuNzA2IDEwNS41NUMxODkuNjgzIDExMi45OTcgMTkwLjM4NiAxMjEuMTYgMTg4LjcyNCAxMjkuMDA3QzE4Ny4wNjIgMTM2Ljg1MyAxODMuMTExIDE0NC4wMyAxNzcuMzcgMTQ5LjYzMUMxNzEuNjI5IDE1NS4yMzIgMTY0LjM1NyAxNTkuMDA0IDE1Ni40NzIgMTYwLjQ3MkMxNTEuMjM2IDE2MS40NDYgMTQ1Ljg2IDE2MS4zODEgMTQwLjY1MSAxNjAuMjc4QzEzNS40NDEgMTU5LjE3NSAxMzAuNSAxNTcuMDU2IDEyNi4xMDkgMTU0LjA0M0MxMjEuNzE4IDE1MS4wMyAxMTcuOTYzIDE0Ny4xODIgMTE1LjA2IDE0Mi43MThDMTEyLjE1NiAxMzguMjU0IDExMC4xNjEgMTMzLjI2MiAxMDkuMTg3IDEyOC4wMjZaTTIxNS43NzIgNDMyLjg0OEMyMDUuMjk0IDQzMi44NDggMTk1LjA1MSA0MjkuNzQgMTg2LjMzOCA0MjMuOTE5QzE3Ny42MjUgNDE4LjA5NyAxNzAuODM1IDQwOS44MjMgMTY2LjgyNSA0MDAuMTQyQzE2Mi44MTUgMzkwLjQ2MSAxNjEuNzY2IDM3OS44MDkgMTYzLjgxIDM2OS41MzJDMTY1Ljg1NCAzNTkuMjU0IDE3MC45IDM0OS44MTQgMTc4LjMxIDM0Mi40MDVDMTg1LjcxOSAzMzQuOTk2IDE5NS4xNTkgMzI5Ljk1IDIwNS40MzYgMzI3LjkwNUMyMTUuNzEzIDMyNS44NjEgMjI2LjM2NiAzMjYuOTEgMjM2LjA0NyAzMzAuOTJDMjQ1LjcyOCAzMzQuOTMgMjU0LjAwMiAzNDEuNzIxIDI1OS44MjQgMzUwLjQzM0MyNjUuNjQ1IDM1OS4xNDYgMjY4Ljc1MiAzNjkuMzg5IDI2OC43NTIgMzc5Ljg2OEMyNjguNzUyIDM5My45MTkgMjYzLjE3IDQwNy4zOTQgMjUzLjIzNSA0MTcuMzNDMjQzLjI5OSA0MjcuMjY2IDIyOS44MjMgNDMyLjg0OCAyMTUuNzcyIDQzMi44NDhaTTMxMy4xNjYgMTQ0LjI0NEMzMDUuMjgxIDE0NS43MSAyOTcuMTM4IDE0NC44MDYgMjg5Ljc2OCAxNDEuNjQ1QzI4Mi4zOTcgMTM4LjQ4NCAyNzYuMTI5IDEzMy4yMDkgMjcxLjc1NiAxMjYuNDg2QzI2Ny4zODQgMTE5Ljc2MyAyNjUuMTAzIDExMS44OTQgMjY1LjIwMiAxMDMuODc1QzI2NS4zMDEgOTUuODU1MyAyNjcuNzc2IDg4LjA0NTUgMjcyLjMxNCA4MS40MzI4QzI3Ni44NTIgNzQuODIgMjgzLjI0OCA2OS43MDEzIDI5MC42OTUgNjYuNzIzOEMyOTguMTQyIDYzLjc0NjMgMzA2LjMwNCA2My4wNDM4IDMxNC4xNSA2NC43MDUxQzMyMS45OTYgNjYuMzY2NCAzMjkuMTczIDcwLjMxNjkgMzM0Ljc3NCA3Ni4wNTdDMzQwLjM3NSA4MS43OTcyIDM0NC4xNDggODkuMDY5MiAzNDUuNjE2IDk2Ljk1MzZDMzQ3LjU4MyAxMDcuNTI4IDM0NS4yNyAxMTguNDUgMzM5LjE4NCAxMjcuMzE5QzMzMy4wOTkgMTM2LjE4OCAzMjMuNzQgMTQyLjI3NSAzMTMuMTY2IDE0NC4yNDRaTTQwNS45NiAyNjguNTU2QzM5OC4wNzUgMjcwLjAyNCAzODkuOTMyIDI2OS4xMjEgMzgyLjU2MSAyNjUuOTYxQzM3NS4xODkgMjYyLjgwMSAzNjguOTIgMjU3LjUyNSAzNjQuNTQ3IDI1MC44MDJDMzYwLjE3NCAyNDQuMDc5IDM1Ny44OTIgMjM2LjIxIDM1Ny45OTEgMjI4LjE5MUMzNTguMDkgMjIwLjE3MSAzNjAuNTY0IDIxMi4zNjEgMzY1LjEwMiAyMDUuNzQ3QzM2OS42NCAxOTkuMTM0IDM3Ni4wMzcgMTk0LjAxNSAzODMuNDg0IDE5MS4wMzdDMzkwLjkzMSAxODguMDYgMzk5LjA5NCAxODcuMzU3IDQwNi45NCAxODkuMDE5QzQxNC43ODcgMTkwLjY4MSA0MjEuOTY0IDE5NC42MzIgNDI3LjU2NSAyMDAuMzczQzQzMy4xNjUgMjA2LjExNCA0MzYuOTM4IDIxMy4zODcgNDM4LjQwNSAyMjEuMjcyQzQzOS4zOCAyMjYuNTA3IDQzOS4zMTQgMjMxLjg4MyA0MzguMjExIDIzNy4wOTJDNDM3LjEwOCAyNDIuMzAyIDQzNC45OSAyNDcuMjQzIDQzMS45NzcgMjUxLjYzNEM0MjguOTY0IDI1Ni4wMjUgNDI1LjExNiAyNTkuNzggNDIwLjY1MiAyNjIuNjgzQzQxNi4xODggMjY1LjU4NyA0MTEuMTk2IDI2Ny41ODIgNDA1Ljk2IDI2OC41NTZaIiBmaWxsPSIjMDBGRjAwIi8+CiAgICA8L3N2Zz4=)'
          )
        })
      })
    })
  })

  describe('when editing mode', () => {
    it('sets the image name', async () => {
      const {getByText, rerender} = subject({editing: true})
      rerender(
        <ImageSection
          {...{
            ...defaultProps,
            ...{
              settings: {
                encodedImage: 'data:image/jpg;base64,asdfasdfjksdf==',
                encodedImageType: 'Course',
                encodedImageName: 'banana.jpg'
              },
              editing: true
            }
          }}
        />
      )
      expect(getByText('banana.jpg')).toBeInTheDocument()
    })

    it('sets the image preview', async () => {
      const {getByTestId, rerender} = subject({editing: true})
      rerender(
        <ImageSection
          {...{
            ...defaultProps,
            ...{
              settings: {
                encodedImage: 'data:image/jpg;base64,asdfasdfjksdf==',
                encodedImageType: 'Course',
                encodedImageName: 'banana.jpg'
              },
              editing: true
            }
          }}
        />
      )
      expect(getByTestId('selected-image-preview')).toHaveStyle(
        'backgroundImage: url(data:image/jpg;base64,asdfasdfjksdf==)'
      )
    })
  })
})
