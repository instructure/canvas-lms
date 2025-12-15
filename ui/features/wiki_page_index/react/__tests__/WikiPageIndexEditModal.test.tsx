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

import {fireEvent, render} from '@testing-library/react'
import {createRoot, Root} from 'react-dom/client'
import WikiPage from '../../../../shared/wiki/backbone/models/WikiPage'
import WikiPageIndexItemView from '../../backbone/views/WikiPageIndexItemView'
import renderWikiPageIndexEditModal, {WikiPageIndexEditModalProps} from '../WikiPageIndexEditModal'
import {TITLE_MAX_LENGTH} from '@canvas/wiki/utils/constants'

const wikiPageModel = new (WikiPage as any)({page_id: 1, title: 'hi'})
wikiPageModel.initialize({url: 'page-1'}, {contextAssetString: 'course_1'})

const viewElement = new (WikiPageIndexItemView as any)({
  model: wikiPageModel,
  editModalRoot: createRoot(document.createElement('div')),
})

const getProps = (
  overrides?: Partial<WikiPageIndexEditModalProps>,
): WikiPageIndexEditModalProps => ({
  model: wikiPageModel as any, // WikiPage is a Backbone model
  modalOpen: true,
  closeModal: vi.fn(),
  ...overrides,
})

describe('renderWikiPageTitle', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('sets the wiki page title to the input', () => {
    const props = getProps()
    const component = renderWikiPageIndexEditModal(
      (viewElement as any).editModalRoot as Root,
      props,
    )
    const {getByTestId} = render(component)

    expect(getByTestId('page-title-input')).toHaveValue('hi')
  })

  it('saves a new title', () => {
    const props = getProps()
    vi.spyOn(props.model, 'set').mockImplementation(() => {})
    const spy = vi.spyOn(props.model, 'save').mockImplementation(() => Promise.resolve())
    const component = renderWikiPageIndexEditModal(
      (viewElement as any).editModalRoot as Root,
      props,
    )
    const {getByTestId} = render(component)

    fireEvent.change(getByTestId('page-title-input'), {target: {value: 'hello'}})
    getByTestId('save-button').click()

    expect(spy).toHaveBeenCalled()
  })

  it.skip('saves on enter', () => {
    const props = getProps()
    vi.spyOn(props.model, 'set').mockImplementation(() => {})
    const spy = vi.spyOn(props.model, 'save').mockImplementation(() => Promise.resolve())
    const component = renderWikiPageIndexEditModal(
      (viewElement as any).editModalRoot as Root,
      props,
    )
    const {getByTestId} = render(component)

    const input = getByTestId('page-title-input')
    fireEvent.change(input, {target: {value: 'hello'}})
    fireEvent.submit(input)

    expect(spy).toHaveBeenCalled()
  })

  it.skip('errors if the title is blank', () => {
    const props = getProps()
    const component = renderWikiPageIndexEditModal(
      (viewElement as any).editModalRoot as Root,
      props,
    )
    const {getByTestId, getByText} = render(component)

    const input = getByTestId('page-title-input')
    fireEvent.change(input, {target: {value: ''}})
    getByTestId('save-button').click()

    expect(input).toHaveFocus()
    expect(getByText('A title is required')).toBeInTheDocument()
  })

  it.skip('errors if the title is too long', () => {
    const props = getProps()
    const component = renderWikiPageIndexEditModal(
      (viewElement as any).editModalRoot as Root,
      props,
    )
    const {getByTestId, getByText} = render(component)

    const input = getByTestId('page-title-input')
    fireEvent.change(input, {target: {value: 'a'.repeat(TITLE_MAX_LENGTH + 1)}})
    getByTestId('save-button').click()

    expect(input).toHaveFocus()
    expect(getByText(`Title can't exceed ${TITLE_MAX_LENGTH} characters`)).toBeInTheDocument()
  })
})
