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
import {render, waitFor, fireEvent, within, screen} from '@testing-library/react'
import FileBrowser from '../FileBrowser'
import {apiSource} from './filesHelpers'

const defaultProps = overrides => ({
  allowedUpload: true,
  selectFile: jest.fn(),
  useContextAssets: false,
  searchString: '',
  onLoading: jest.fn(),
  context: {
    type: 'course',
    id: '1',
  },
  contentTypes: ['**'],
  source: apiSource(),
  ...overrides,
})

const subject = props => render(<FileBrowser {...props} />)

describe('FileBrowser', () => {
  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('componentDidMount()', () => {
    let props

    beforeEach(() => (props = defaultProps()))

    it('does not fetch the context root folder', async () => {
      const {queryByText} = subject(props)
      const folder = await waitFor(() => queryByText('Course files'))
      expect(folder).not.toBeInTheDocument()
    })

    it('fetches and renders the user root folder', async () => {
      const {getByText} = subject(props)
      const folder = await waitFor(() => getByText('My files'))
      expect(folder).toBeInTheDocument()
    })

    it('fetches root user folder data', async () => {
      const {getByText} = subject(props)
      await waitFor(() => getByText('My files'))
      expect(props.source.fetchBookmarkedData).toHaveBeenCalled()
    })

    it('fetches root user folder files', async () => {
      const {getByText} = subject(props)
      const folder = await waitFor(() => getByText('My files'))

      fireEvent.click(folder)
      const file = await waitFor(() => getByText('its-working-its-working.jpg'))
      expect(file).toBeInTheDocument()
    })

    it('renders titles on items', async () => {
      subject(props)
      const folder = await screen.findByText('My files')
      fireEvent.click(folder)
      const elements = await screen.findAllByRole('treeitem')
      const items = elements.filter(elem => !['Course files', 'My files'].includes(elem.name))
      items.forEach(item => {
        expect(item.title === item.getAttribute('aria-label'))
      })
    })

    describe('when a media file is still processing', () => {
      it('the view contains the file name and a "media ... processing..." message', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))
        fireEvent.click(folder)
        const mediaProcessingMessage = await waitFor(() =>
          getByText('Media file is processing. Please try again later.')
        )
        const pendingMediaFileName = await waitFor(() => getByText('im-still-pending.mp4'))

        expect(mediaProcessingMessage).toBeInTheDocument()
        expect(pendingMediaFileName).toBeInTheDocument()
      })

      it('clicking on the file does not invoke "selectFile"', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))
        fireEvent.click(folder)
        const pendingMediaFileName = await waitFor(() => getByText('im-still-pending.mp4'))
        fireEvent.click(pendingMediaFileName)
        expect(props.selectFile).not.toHaveBeenCalled()
      })
    })

    describe('when file is an Icon Maker icon', () => {
      it('clicking on the file invokes "selectFile"', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))
        fireEvent.click(folder)
        const iconMakerFile = await waitFor(() => getByText('icon-maker-icon.svg'))
        expect(iconMakerFile).toBeInTheDocument()
        fireEvent.click(iconMakerFile)
        expect(props.selectFile).toHaveBeenCalled()
      })
    })

    describe('when "useContextAssets" is true', () => {
      beforeEach(() => (props = defaultProps({useContextAssets: true})))

      it('fetches and renders the context root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('Course files'))
        expect(folder).toBeInTheDocument()
      })

      it('fetches and renders the user root folder', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))
        expect(folder).toBeInTheDocument()
      })

      it('fetches course folder files', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('Course files'))
        fireEvent.click(folder)
        const file = await waitFor(() => getByText('its-working-its-working.jpg'))
        expect(file).toBeInTheDocument()
      })

      it('fetches root user folder files', async () => {
        const {getByText} = subject(props)
        const folder = await waitFor(() => getByText('My files'))

        fireEvent.click(folder)
        const file = await waitFor(() => getByText('its-working-its-working.jpg'))
        expect(file).toBeInTheDocument()
      })
    })
  })

  describe('file icon', () => {
    const getIconFor = async filename => {
      return waitFor(() => {
        const folderButton = screen.getByRole('button', {name: filename})
        return within(folderButton).getAllByRole('presentation', {hidden: true})[0].outerHTML
      })
    }

    beforeEach(async () => {
      const {getByText} = subject(defaultProps())
      const folder = await waitFor(() => getByText('My files'))
      fireEvent.click(folder)
    })

    it('is an img thumbnail if the file is an image and has a thumbnailUrl', async () => {
      const icon = await waitFor(() => {
        const folderButton = screen.getByRole('button', {name: 'its-working-its-working.jpg'})
        return within(folderButton).getByRole('img')
      })
      expect(icon.src).toEqual(
        'http://canvas.docker/images/thumbnails/172/KEI31pWCjvr1yK3xOT0pwLUGnzxTQ0HEVjiCKqhQ'
      )
    })

    it('is an Image icon if the file is an image without a thumbnailUrl', async () => {
      const icon = await getIconFor('no-thumbnail.jpg')
      expect(icon).toMatch(/IconImage/)
    })

    it('is an MsWord icon if the file is a document', async () => {
      const icon = await getIconFor('doc.docx')
      expect(icon).toMatch(/IconMsWord/)
    })

    it('is an MsPpt icon if the file is a slide deck', async () => {
      const icon = await getIconFor('slides.pptx')
      expect(icon).toMatch(/IconMsPpt/)
    })

    it('is a Pdf icon if the file is a pdf', async () => {
      const icon = await getIconFor('pdf.pdf')
      expect(icon).toMatch(/IconPdf/)
    })

    it('is a MsExcel icon if the file is a spreadsheet', async () => {
      const icon = await getIconFor('spreadsheet.xlsx')
      expect(icon).toMatch(/IconMsExcel/)
    })

    it('is a Video icon if the file is a video', async () => {
      const icon = await getIconFor('vid.mov')
      expect(icon).toMatch(/IconVideo/)
    })

    it('is an Audio icon if the file is audio', async () => {
      const icon = await getIconFor('sound.mp4')
      expect(icon).toMatch(/IconAudio/)
    })

    it('is a Document icon if the file does not fit in the other categories', async () => {
      const icon = await getIconFor('docker-compose.override.yml')
      expect(icon).toMatch(/IconDocument/)
    })
  })
})
