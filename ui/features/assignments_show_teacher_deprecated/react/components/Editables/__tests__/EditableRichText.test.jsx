// @vitest-environment jsdom
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
import {render} from '@testing-library/react'
import EditableRichText from '../EditableRichText'

it('renders the value in view mode', () => {
  const {getByText} = render(
    <EditableRichText
      mode="view"
      value="<p>I am a paragraph of text</p>"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="The Label"
    />
  )

  expect(getByText('I am a paragraph of text')).toBeInTheDocument()
  expect(getByText('The Label')).toBeInTheDocument()
})

// Note: Cannot test edit mode since the RichContentEditor mock doesn't render
// anything. Eventually, it will become testable using jest and we can revisit
// it('renders the value in edit mode', () => {
//   const {container, getByText} = render(
//     <EditableRichText
//       mode="edit"
//       value="<p>I am a paragraph of text</p>"
//       onChange={() => {}}
//       onChangeMode={() => {}}
//       label="The Label"
//     />
//   )
//
//   expect(getByText('I am a paragraph of text')).toBeInTheDocument()
//   expect(container.querySelector('iframe')).toBeInTheDocument()
//   expect(container.querySelector('textarea').innerHTML).toEqual('<p>I am a paragraph of text</p>')
// })

it('does not render edit button when readOnly', () => {
  const {queryByText} = render(
    <EditableRichText
      mode="view"
      value="<p>I am a paragraph of text</p>"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="The Label"
      readOnly={true}
    />
  )
  expect(queryByText('The Label')).toBeNull()
})

it('shows the placeholder when value is all whitespace', () => {
  const {getByText} = render(
    <EditableRichText
      mode="view"
      value="<p>&nbsp; </p>"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="The Label"
      placeholder="the placeholder"
    />
  )
  expect(getByText('the placeholder')).toBeInTheDocument()
})

it('shows the content and not the placeholder when value is all whitespace and readOnly=true', () => {
  const {getAllByText, queryByText} = render(
    <EditableRichText
      mode="view"
      value="<p>&nbsp;</p>"
      onChange={() => {}}
      onChangeMode={() => {}}
      label="The Label"
      placeholder="the placeholder"
      readOnly={true}
    />
  )
  expect(queryByText('the placeholder')).toBeNull()
  expect(
    getAllByText((_content, element) => /<p>&nbsp;<\/p>/.test(element.innerHTML))[0]
  ).toBeInTheDocument()
})
