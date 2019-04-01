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
import {render, fireEvent} from 'react-testing-library'
import Filter from '../Filter'

it('shows subtype and sort options when contentType is set to files', () => {

  const {getByLabelText, getByText} = render(
    <Filter onChange={() => {}} />
  )

  const contentTypeSelect = getByLabelText('Content Type');
  fireEvent.click(contentTypeSelect)
  fireEvent.click(getByText('Files'))
  expect(getByLabelText('Content Subtype')).toBeVisible()
  expect(getByLabelText('Sort By')).toBeVisible()
})

it('calls the onChange prop when modifying the content type', () => {
  const fakeChange = jest.fn();
  const {getByLabelText, getByText} = render(
    <Filter onChange={fakeChange} />
  )

  const contentTypeSelect = getByLabelText('Content Type');
  fireEvent.click(contentTypeSelect)
  fireEvent.click(getByText('Files'))
  expect(fakeChange).toHaveBeenCalledWith({"contentSubtype": "", "contentType": "files", "sortValue": "date_added"});
});
it('calls the onChange prop when modifying the content subtype', () => {
  const fakeChange = jest.fn();
  const {getByLabelText, getByText} = render(
    <Filter onChange={fakeChange} />
  )

  const contentTypeSelect = getByLabelText('Content Type');
  fireEvent.click(contentTypeSelect)
  fireEvent.click(getByText('Files'))
  fireEvent.click(getByLabelText('Content Subtype'))
  fireEvent.click(getByText('Images'))
  expect(fakeChange).toHaveBeenNthCalledWith(2, {"contentSubtype": "images", "contentType": "files", "sortValue": "date_added"});
});
it('calls the onChange prop when modifying the sort value', () => {
  const fakeChange = jest.fn();
  const {getByLabelText, getByText} = render(
    <Filter onChange={fakeChange} />
  )

  const contentTypeSelect = getByLabelText('Content Type');
  fireEvent.click(contentTypeSelect)
  fireEvent.click(getByText('Files'))
  fireEvent.click(getByLabelText('Sort By'))
  fireEvent.click(getByText('Alphabetical'))
  expect(fakeChange).toHaveBeenCalledWith({"contentSubtype": "", "contentType": "files", "sortValue": "alphabetical"});
});
