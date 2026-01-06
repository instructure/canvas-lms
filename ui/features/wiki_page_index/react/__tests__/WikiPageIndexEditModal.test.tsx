/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {act, fireEvent, screen, waitFor} from '@testing-library/react'
import {createRoot, Root} from 'react-dom/client'
import WikiPage from '../../../../shared/wiki/backbone/models/WikiPage'
import renderWikiPageIndexEditModal, {WikiPageIndexEditModalProps} from '../WikiPageIndexEditModal'
import {TITLE_MAX_LENGTH} from '@canvas/wiki/utils/constants'

const createWikiPageModel = () => {
  const model = new (WikiPage as any)({page_id: 1, title: 'hi'})
  model.initialize({url: 'page-1'}, {contextAssetString: 'course_1'})
  return model
}

const getProps = (
  model: any,
  overrides?: Partial<WikiPageIndexEditModalProps>,
): WikiPageIndexEditModalProps => ({
  model: model as any, // WikiPage is a Backbone model
  modalOpen: true,
  closeModal: vi.fn(),
  ...overrides,
})

describe('renderWikiPageTitle', () => {
  let container: HTMLDivElement
  let root: Root

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    root = createRoot(container)
  })

  afterEach(() => {
    act(() => {
      root.unmount()
    })
    container.remove()
    vi.restoreAllMocks()
  })

  it('sets the wiki page title to the input', () => {
    const wikiPageModel = createWikiPageModel()
    const props = getProps(wikiPageModel)
    act(() => {
      renderWikiPageIndexEditModal(root, props)
    })

    expect(screen.getByTestId('page-title-input')).toHaveValue('hi')
  })

  it('saves a new title', () => {
    const wikiPageModel = createWikiPageModel()
    const props = getProps(wikiPageModel)
    vi.spyOn(props.model, 'set').mockImplementation(() => {})
    const spy = vi.spyOn(props.model, 'save').mockImplementation(() => Promise.resolve())
    act(() => {
      renderWikiPageIndexEditModal(root, props)
    })

    fireEvent.change(screen.getByTestId('page-title-input'), {target: {value: 'hello'}})
    screen.getByTestId('save-button').click()

    expect(spy).toHaveBeenCalled()
  })

  it('saves on enter', () => {
    const wikiPageModel = createWikiPageModel()
    const props = getProps(wikiPageModel)
    vi.spyOn(props.model, 'set').mockImplementation(() => {})
    const spy = vi.spyOn(props.model, 'save').mockImplementation(() => Promise.resolve())
    act(() => {
      renderWikiPageIndexEditModal(root, props)
    })

    const input = screen.getByTestId('page-title-input')
    fireEvent.change(input, {target: {value: 'hello'}})
    fireEvent.submit(input)

    expect(spy).toHaveBeenCalled()
  })

  it('errors if the title is blank', async () => {
    const wikiPageModel = createWikiPageModel()
    const props = getProps(wikiPageModel)
    act(() => {
      renderWikiPageIndexEditModal(root, props)
    })

    const input = screen.getByTestId('page-title-input')
    fireEvent.change(input, {target: {value: ''}})
    screen.getByTestId('save-button').click()

    await waitFor(() => {
      expect(screen.getByText('A title is required')).toBeInTheDocument()
    })
    expect(input).toHaveFocus()
  })

  it('errors if the title is too long', async () => {
    const wikiPageModel = createWikiPageModel()
    const props = getProps(wikiPageModel)
    act(() => {
      renderWikiPageIndexEditModal(root, props)
    })

    const input = screen.getByTestId('page-title-input')
    fireEvent.change(input, {target: {value: 'a'.repeat(TITLE_MAX_LENGTH + 1)}})
    screen.getByTestId('save-button').click()

    await waitFor(() => {
      expect(
        screen.getByText(`Title can't exceed ${TITLE_MAX_LENGTH} characters`),
      ).toBeInTheDocument()
    })
    expect(input).toHaveFocus()
  })
})
