/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ApiProgressBar from '../ApiProgressBar'
import ProgressStore from '../../../stores/ProgressStore'

describe('ApiProgressBar', () => {
  const defaultProgress = {
    id: '1',
    context_id: 1,
    context_type: 'EpubExport',
    user_id: 1,
    tag: 'epub_export',
    completion: 0,
    workflow_state: 'queued',
  }

  const renderComponent = (props = {}) => {
    return render(<ApiProgressBar {...props} />)
  }

  beforeEach(() => {
    jest.useFakeTimers()
    jest.spyOn(ProgressStore, 'get').mockImplementation(() => {
      ProgressStore.setState({[defaultProgress.id]: defaultProgress})
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
    ProgressStore.clearState()
    jest.useRealTimers()
  })

  it('does not render initially when not in progress', () => {
    const {container} = renderComponent()
    expect(container.firstChild).toBeNull()
  })

  it('renders progress bar when in progress', () => {
    const {getByTestId} = renderComponent({progress_id: defaultProgress.id})
    jest.advanceTimersByTime(1000)
    expect(getByTestId('api-progress-bar')).toBeInTheDocument()
  })

  it('updates when progress state changes', () => {
    const {getByTestId} = renderComponent({progress_id: defaultProgress.id})
    jest.advanceTimersByTime(1000)

    // Update progress state to running
    const updatedProgress = {...defaultProgress, workflow_state: 'running', completion: 50}
    ProgressStore.setState({[defaultProgress.id]: updatedProgress})

    const progressBar = getByTestId('api-progress-bar')
    expect(progressBar).toBeInTheDocument()
    expect(progressBar.querySelector('[role="progressbar"]')).toHaveAttribute('aria-valuenow', '50')
  })

  it('calls onComplete when progress is completed', () => {
    const onComplete = jest.fn()
    renderComponent({progress_id: defaultProgress.id, onComplete})
    jest.advanceTimersByTime(1000)

    // Update progress state to completed
    const completedProgress = {...defaultProgress, workflow_state: 'completed', completion: 100}
    ProgressStore.setState({[defaultProgress.id]: completedProgress})

    expect(onComplete).toHaveBeenCalled()
  })

  it('stops polling when progress is completed', () => {
    const {queryByTestId} = renderComponent({progress_id: defaultProgress.id})
    jest.advanceTimersByTime(1000)

    // Update progress state to completed
    const completedProgress = {...defaultProgress, workflow_state: 'completed', completion: 100}
    ProgressStore.setState({[defaultProgress.id]: completedProgress})
    jest.advanceTimersByTime(1000)

    expect(queryByTestId('api-progress-bar')).not.toBeInTheDocument()
  })

  it('starts polling when progress_id is provided', () => {
    renderComponent({progress_id: defaultProgress.id})
    jest.advanceTimersByTime(1000)
    expect(ProgressStore.get).toHaveBeenCalled()
  })

  it('does not start polling when no progress_id is provided', () => {
    renderComponent()
    jest.advanceTimersByTime(1000)
    expect(ProgressStore.get).not.toHaveBeenCalled()
  })

  describe('progress states', () => {
    it('shows progress bar in queued state', () => {
      const {getByTestId} = renderComponent({progress_id: defaultProgress.id})
      jest.advanceTimersByTime(1000)
      const progressBar = getByTestId('api-progress-bar')
      expect(progressBar).toBeInTheDocument()
      expect(progressBar.querySelector('[role="progressbar"]')).toHaveAttribute(
        'aria-valuenow',
        '0',
      )
    })

    it('shows progress bar in running state', () => {
      const {getByTestId} = renderComponent({progress_id: defaultProgress.id})
      jest.advanceTimersByTime(1000)

      const runningProgress = {...defaultProgress, workflow_state: 'running', completion: 75}
      ProgressStore.setState({[defaultProgress.id]: runningProgress})

      const progressBar = getByTestId('api-progress-bar')
      expect(progressBar).toBeInTheDocument()
      expect(progressBar.querySelector('[role="progressbar"]')).toHaveAttribute(
        'aria-valuenow',
        '75',
      )
    })

    it('removes progress bar in completed state', () => {
      const {queryByTestId} = renderComponent({progress_id: defaultProgress.id})
      jest.advanceTimersByTime(1000)

      const completedProgress = {...defaultProgress, workflow_state: 'completed', completion: 100}
      ProgressStore.setState({[defaultProgress.id]: completedProgress})

      expect(queryByTestId('api-progress-bar')).not.toBeInTheDocument()
    })
  })
})
