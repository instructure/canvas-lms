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

import React from 'react'
import PeerReviewPromptModal, {
  type PeerReviewPromptModalProps,
  type PeerReviewSubheader,
} from '../PeerReviewPromptModal'
import {fireEvent, render} from '@testing-library/react'

describe('PeerReviewPromptModal', () => {
  let onRedirect: jest.Mock<any, any>
  let onClose: jest.Mock<any, any>

  beforeEach(() => {
    onRedirect = jest.fn()
    onClose = jest.fn()
  })

  type RenderHelperProps = Pick<
    PeerReviewPromptModalProps,
    'headerText' | 'subHeaderText' | 'peerReviewButtonText' | 'peerReviewButtonDisabled'
  >
  const sampleHeaderText = ['Your work has been submitted.', 'Check back later to view feedback.']
  const sampleSubHeaderText: PeerReviewSubheader[] = [
    {text: 'You have 2 Peer Reviews to complete', props: {size: 'medium'}},
    {text: 'Peer submissions ready for review: 1', props: {size: 'medium'}},
  ]
  const peerReviewButtonText = 'Peer Review'

  function renderComponent(
    props: RenderHelperProps = {
      headerText: sampleHeaderText,
      peerReviewButtonDisabled: false,
      peerReviewButtonText,
      subHeaderText: sampleSubHeaderText,
    }
  ) {
    return render(
      <PeerReviewPromptModal onRedirect={onRedirect} onClose={onClose} open={true} {...props} />
    )
  }

  describe('with hasSubmittedText set as true', () => {
    it('properly renders header, subheader, and button text', () => {
      const {getByText, getByRole} = renderComponent()
      sampleHeaderText.forEach(headerText => expect(getByText(headerText)).toBeInTheDocument())
      sampleSubHeaderText.forEach(subHeaderText =>
        expect(getByText(subHeaderText.text)).toBeInTheDocument()
      )
      expect(getByText(peerReviewButtonText)).toBeInTheDocument()
      expect(getByRole('button', {name: /Peer Review/})).toBeEnabled()
    })

    it('calls onRedirect when the Peer Review button in footer is clicked', () => {
      const {getByRole} = renderComponent()
      fireEvent.click(getByRole('button', {name: /Peer Review/}))
      expect(onRedirect).toHaveBeenCalled()
    })

    it('calls onClose when the Close button in header is clicked', () => {
      const {getAllByRole} = renderComponent()
      fireEvent.click(getAllByRole('button', {name: /Close/})[0])
      expect(onClose).toHaveBeenCalled()
    })

    it('calls onClose when the modal close button in footer is clicked', () => {
      const {getAllByRole} = renderComponent()
      fireEvent.click(getAllByRole('button', {name: /Close/})[1])
      expect(onClose).toHaveBeenCalled()
    })

    it('does disable the Peer Review button when peerReviewButtonDisabled is true', () => {
      const {getByRole} = renderComponent({
        headerText: sampleHeaderText,
        peerReviewButtonDisabled: true,
        peerReviewButtonText,
        subHeaderText: sampleSubHeaderText,
      })
      expect(getByRole('button', {name: /Peer Review/})).toBeDisabled()
    })
  })
})
