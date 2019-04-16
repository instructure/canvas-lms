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

import React, {useRef} from 'react'
import {fireEvent, render} from 'react-testing-library'

import LoadMoreButton from '../LoadMoreButton'

describe('RCE > LoadMoreButton', () => {
  let props
  let component

  beforeEach(() => {
    props = {
      isLoading: false,
      onLoadMore: jest.fn()
    }
  })

  function SpecComponent() {
    // `useRef()` can only be used within a component render
    props.buttonRef = useRef(null)

    return <LoadMoreButton {...props} />
  }

  function renderComponent() {
    component = render(<SpecComponent />)
  }

  function getButton() {
    return component.container.querySelector('button')
  }

  describe('when not loading', () => {
    it('is labeled with "Load more results"', () => {
      renderComponent()
      expect(getButton().textContent).toMatch(/Load more results/)
    })

    it('calls the `onLoadMore` callback prop when clicked', () => {
      renderComponent()
      fireEvent.click(getButton())
      expect(props.onLoadMore).toHaveBeenCalledTimes(1)
    })

    it('forwards the .buttonRef prop to the `button` component', () => {
      renderComponent()
      expect(props.buttonRef.current).toEqual(getButton())
    })
  })

  describe('when loading', () => {
    beforeEach(() => {
      props.isLoading = true
    })

    it('is labeled with "Loading more results..."', () => {
      renderComponent()
      expect(getButton().textContent).toMatch(/Loading more results/)
    })

    it('does not call the `onLoadMore` callback prop when clicked', () => {
      renderComponent()
      fireEvent.click(getButton())
      expect(props.onLoadMore).toHaveBeenCalledTimes(0)
    })

    it('forwards the .buttonRef prop to the `button` component', () => {
      renderComponent()
      expect(props.buttonRef.current).toEqual(getButton())
    })
  })
})
