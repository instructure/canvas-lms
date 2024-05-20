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
import WikiPage from '../../backbone/models/WikiPage'
import WikiPageEditView from '../../backbone/views/WikiPageEditView'
import renderWikiPageTitle from '../renderWikiPageTitle'
import type {Props as ComponentProps} from '../renderWikiPageTitle'
import type JQuery from 'jquery'
import {checkForTitleConflictDebounced} from '../../utils/titleConflicts'

jest.mock('../../utils/titleConflicts')

const wikiPageModel = new WikiPage()
wikiPageModel.initialize({url: 'page-1'}, {contextAssetString: 'course_1'})
const viewElement = new WikiPageEditView({
  model: wikiPageModel,
  wiki_pages_path: '/courses/1/pages',
})

const getProps = (overrides?: {[k: string]: any}): ComponentProps => ({
  canEdit: true,
  defaultValue: 'Test Title',
  viewElement: viewElement as unknown as JQuery<HTMLFormElement> & WikiPageEditView,
  validationCallback: jest.fn(),
  isContentLocked: false,
  ...overrides,
})

describe('renderWikiPageTitle', () => {
  it('sets the wikipage title to the input', () => {
    const props = getProps()
    const component = renderWikiPageTitle(props)
    const {getByTestId} = render(component)

    expect(getByTestId('wikipage-title-input')).toHaveValue(props.defaultValue)
  })

  it('locks title if content is locked', () => {
    const props = getProps({isContentLocked: true})
    const component = renderWikiPageTitle(props)
    const {getByTestId, getByText} = render(component)

    expect(getByTestId('wikipage-locked-title')).toBeInTheDocument()
    expect(getByText('Test Title')).toBeInTheDocument()
  })

  it('renders a read-only view if the title is not editable', () => {
    const props = getProps({canEdit: false})
    const component = renderWikiPageTitle(props)
    const {getByTestId, getByText} = render(component)

    expect(getByTestId('wikipage-readonly-title')).toBeInTheDocument()
    expect(getByText('Test Title')).toBeInTheDocument()
  })

  it('calls validationCallback when submitting', () => {
    const titleErrors = [{message: 'title is required', type: 'required'}]
    const callback = jest.fn(() => ({title: titleErrors}))
    const props = getProps({validationCallback: callback})
    const component = renderWikiPageTitle(props)

    const {getByText} = render(component)
    props.viewElement.submit()
    expect(getByText(titleErrors[0].message)).toBeInTheDocument()
    expect(callback).toHaveBeenCalled()
  })

  describe('handleOnChange', () => {
    afterEach(() => {
      jest.clearAllMocks()
    })

    it('calls checkForTitleConflictDebounced onChange', () => {
      const {getByTestId} = render(renderWikiPageTitle(getProps()))
      const input = getByTestId('wikipage-title-input')
      fireEvent.change(input, {target: {value: 'New Title'}})
      expect(checkForTitleConflictDebounced).toHaveBeenCalledWith('New Title', expect.any(Function))
    })

    it('does not call checkForTitleConflictDebounced when new value is the same as old value', () => {
      const {getByTestId} = render(renderWikiPageTitle(getProps()))
      const input = getByTestId('wikipage-title-input')
      fireEvent.change(input, {target: {value: getProps().defaultValue}})
      expect(checkForTitleConflictDebounced).not.toHaveBeenCalled()
    })

    it('does not call checkForTitleConflictDebounced when new value is the empty string', () => {
      const {getByTestId} = render(renderWikiPageTitle(getProps()))
      const input = getByTestId('wikipage-title-input')
      fireEvent.change(input, {target: {value: ''}})
      expect(checkForTitleConflictDebounced).not.toHaveBeenCalled()
    })

    it('does not call checkForTitleConflictDebounced when new value is whitepace', () => {
      const {getByTestId} = render(renderWikiPageTitle(getProps()))
      const input = getByTestId('wikipage-title-input')
      fireEvent.change(input, {target: {value: '       '}})
      expect(checkForTitleConflictDebounced).not.toHaveBeenCalled()
    })
  })
})
