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

import {act, fireEvent, render} from '@testing-library/react'
import React from 'react'
import SimilarityPledge from '../SimilarityPledge'

describe('SimilarityPledge', () => {
  it('calls the onChange property when the checkbox is toggled', () => {
    const onChange = jest.fn()

    const {getByRole} = render(
      <SimilarityPledge checked={true} eulaUrl="http://some.url" onChange={onChange} />
    )
    const checkbox = getByRole('checkbox', {name: /I agree/})
    act(() => {
      fireEvent.click(checkbox)
    })

    expect(onChange).toHaveBeenCalled()
  })

  it('renders any supplied comments as HTML', () => {
    const comments = '<p>Here are some comments</p><p>And some more</p>'

    const {getByTestId} = render(
      <SimilarityPledge
        checked={true}
        comments={comments}
        eulaUrl="http://some.url"
        onChange={jest.fn()}
      />
    )

    const commentsContainer = getByTestId('similarity-pledge-comments')
    expect(commentsContainer.innerHTML).toEqual(
      expect.stringMatching(/<p>Here are some comments<\/p>\s*<p>And some more<\/p>/)
    )
  })

  it('includes a link to the supplied eulaUrl when one is provided', () => {
    const {getByRole} = render(
      <SimilarityPledge checked={true} eulaUrl="http://some.url/" onChange={jest.fn()} />
    )

    const eulaLink = getByRole('link', {name: 'End-User License Agreement'})
    expect(eulaLink.href).toBe('http://some.url/')
  })

  it('renders the value of pledgeText as the checkbox label when no eulaUrl is given', () => {
    const {getByLabelText} = render(
      <SimilarityPledge
        checked={true}
        pledgeText="a grave and solemn pledge"
        onChange={jest.fn()}
      />
    )

    const checkbox = getByLabelText('a grave and solemn pledge')
    expect(checkbox).toBeInTheDocument()
  })

  it('renders the eulaUrl when both eulaUrl and pledgeText are provided', () => {
    const {getByLabelText} = render(
      <SimilarityPledge
        checked={true}
        eulaUrl="http://some.url"
        pledgeText="a grave and solemn pledge"
        onChange={jest.fn()}
      />
    )

    expect(getByLabelText(/I agree to the tool's End-User License Agreement/)).toBeInTheDocument()
  })

  it('renders the pledgeText when both eulaUrl and pledgeText are provided', () => {
    const {getByLabelText} = render(
      <SimilarityPledge
        checked={true}
        eulaUrl="http://some.url"
        pledgeText="a grave and solemn pledge"
        onChange={jest.fn()}
      />
    )

    expect(getByLabelText(/a grave and solemn pledge/)).toBeInTheDocument()
  })

  it('checks the checkbox if "checked" is true', () => {
    const {getByLabelText} = render(
      <SimilarityPledge checked={true} onChange={jest.fn()} pledgeText="a grave and solemn oath" />
    )

    const checkbox = getByLabelText('a grave and solemn oath')
    expect(checkbox).toBeChecked()
  })

  it('does not check the checkbox if "checked" is false"', () => {
    const {getByLabelText} = render(
      <SimilarityPledge checked={false} onChange={jest.fn()} pledgeText="a grave and solemn vow" />
    )

    const checkbox = getByLabelText('a grave and solemn vow')
    expect(checkbox).not.toBeChecked()
  })
})
