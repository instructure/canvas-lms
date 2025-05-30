/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {render, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {merge} from 'lodash'
import ConfirmOutcomeEditModal, {showConfirmOutcomeEdit} from '../ConfirmOutcomeEditModal'

const defaultProps = (props = {}) =>
  merge(
    {
      changed: true,
      assessed: true,
      hasUpdateableRubrics: false,
      modifiedFields: {
        masteryPoints: false,
        scoringMethod: false,
      },
      parent: () => {},
      onConfirm: () => {},
    },
    props,
  )

it('renders the ConfirmOutcomeEditModal component', async () => {
  const modalRef = React.createRef()
  const {getByRole} = render(
    <ConfirmOutcomeEditModal {...defaultProps({hasUpdateableRubrics: true})} ref={modalRef} />,
  )

  // Open the modal by calling the show method
  await act(async () => {
    if (modalRef.current) {
      modalRef.current.show()
    }
  })

  expect(getByRole('dialog')).toBeInTheDocument()
})

it('renders the rubrics text if hasUpdateableRubrics', async () => {
  const modalRef = React.createRef()
  const {getByText} = render(
    <ConfirmOutcomeEditModal {...defaultProps({hasUpdateableRubrics: true})} ref={modalRef} />,
  )

  // Open the modal by calling the show method
  await act(async () => {
    if (modalRef.current) {
      modalRef.current.show()
    }
  })

  expect(getByText(/update all rubrics/)).toBeInTheDocument()
})

it('renders the masteryPoints text if mastery points modified', async () => {
  const modalRef = React.createRef()
  const {getByText} = render(
    <ConfirmOutcomeEditModal
      {...defaultProps({modifiedFields: {masteryPoints: true}})}
      ref={modalRef}
    />,
  )

  // Open the modal by calling the show method
  await act(async () => {
    if (modalRef.current) {
      modalRef.current.show()
    }
  })

  expect(getByText(/scoring criteria/)).toBeInTheDocument()
})

it('renders the scoring method text if scoring method modified', async () => {
  const modalRef = React.createRef()
  const {getByText} = render(
    <ConfirmOutcomeEditModal
      {...defaultProps({modifiedFields: {scoringMethod: true}})}
      ref={modalRef}
    />,
  )

  // Open the modal by calling the show method
  await act(async () => {
    if (modalRef.current) {
      modalRef.current.show()
    }
  })

  expect(getByText(/scoring criteria/)).toBeInTheDocument()
})

it('does not call onConfirm when canceled', async () => {
  const onConfirm = jest.fn()
  const modalRef = React.createRef()
  const {getByRole} = render(
    <ConfirmOutcomeEditModal
      {...defaultProps({hasUpdateableRubrics: true, onConfirm})}
      ref={modalRef}
    />,
  )

  // Open the modal by calling the show method
  await act(async () => {
    if (modalRef.current) {
      modalRef.current.show()
    }
  })

  // Test that cancel button exists and test direct onCancel method
  const cancelButton = getByRole('button', {name: /cancel/i})
  expect(cancelButton).toBeInTheDocument()

  // Call onCancel directly to test the behavior
  act(() => {
    if (modalRef.current) {
      modalRef.current.onCancel()
    }
  })

  expect(onConfirm).not.toHaveBeenCalled()
})

it('calls onConfirm when saved', async () => {
  const onConfirm = jest.fn()
  const modalRef = React.createRef()
  const {getByRole} = render(
    <ConfirmOutcomeEditModal
      {...defaultProps({hasUpdateableRubrics: true, onConfirm})}
      ref={modalRef}
    />,
  )

  // Open the modal by calling the show method
  await act(async () => {
    if (modalRef.current) {
      modalRef.current.show()
    }
  })

  // Test that save button exists and test direct onConfirm method
  const saveButton = getByRole('button', {name: /save/i})
  expect(saveButton).toBeInTheDocument()

  // Call onConfirm directly to test the behavior
  jest.useFakeTimers()
  act(() => {
    if (modalRef.current) {
      modalRef.current.onConfirm()
    }
  })
  jest.runAllTimers()

  expect(onConfirm).toHaveBeenCalled()
  jest.useRealTimers()
})

describe('showConfirmOutcomeEdit', () => {
  afterEach(() => {
    const parent = document.querySelector('.confirm-outcome-edit-modal-container')
    if (parent) {
      const skipScroll = jest.spyOn(window, 'scroll').mockImplementation(() => {})
      ReactDOM.unmountComponentAtNode(parent)
      parent.remove()
      skipScroll.mockRestore()
    }
  })

  const doesNotRenderFor = props => {
    const onConfirm = jest.fn()

    jest.useFakeTimers()
    showConfirmOutcomeEdit({...props, onConfirm})
    jest.runAllTimers()

    expect(onConfirm).toHaveBeenCalled()
    expect(document.querySelector('.confirm-outcome-edit-modal-container')).toBeNull()
  }

  const rendersFor = props => {
    const app = document.createElement('div')
    app.setAttribute('id', 'application')
    document.body.appendChild(app)

    const onConfirm = jest.fn()

    jest.useFakeTimers()
    showConfirmOutcomeEdit({...props, onConfirm})
    jest.runAllTimers()

    expect(onConfirm).not.toHaveBeenCalled()
    expect(document.querySelector('.confirm-outcome-edit-modal-container')).not.toBeNull()
  }

  it('does not render a dialog if nothing updateable and not modified', () => {
    doesNotRenderFor(defaultProps())
  })

  it('renders a dialog if has updateable rubrics', () => {
    rendersFor(defaultProps({hasUpdateableRubrics: true}))
  })

  it('does not render a dialog if not assessed', () => {
    doesNotRenderFor(defaultProps({assessed: false, modifiedFields: {masteryPoints: true}}))
  })

  it('renders a dialog if masteryPoints modified', () => {
    rendersFor(defaultProps({modifiedFields: {masteryPoints: true}}))
  })

  it('renders a dialog if scoringMethod modified', () => {
    rendersFor(defaultProps({modifiedFields: {scoringMethod: true}}))
  })

  it('does not render a dialog if unchanged', () => {
    doesNotRenderFor(defaultProps({changed: false}))
  })
})
