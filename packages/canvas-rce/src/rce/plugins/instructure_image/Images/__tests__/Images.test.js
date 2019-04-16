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
import {fireEvent, render} from 'react-testing-library'

import {buildImage} from '../../../../../sidebar/sources/fake'
import Images from '..'

describe('RCE "Images" Plugin > Images', () => {
  let component
  let props

  beforeEach(() => {
    component = null

    props = {
      fetchImages: jest.fn(),
      images: {
        hasMore: false,
        isLoading: false,
        records: []
      },
      onImageEmbed() {}
    }
  })

  function renderComponent() {
    if (component) {
      // Update the existing instance when previously rendered
      component.rerender(<Images {...props} />)
    } else {
      component = render(<Images {...props} />)
    }
  }

  function getInitialLoadIndicator() {
    return component.queryByTitle('Loading...')
  }

  function getImages() {
    return component.container.querySelectorAll('img')
  }

  function getLoadMoreButton(label) {
    return [...component.container.querySelectorAll('button')].find(
      $button => $button.textContent.match(label)
    ) || null
  }

  describe('upon initial render', () => {
    it('calls the .fetchImages prop', () => {
      renderComponent()
      expect(props.fetchImages).toHaveBeenCalledTimes(1)
    })

    it('includes .calledFromRender set to `true` when calling .fetchImages', () => {
      renderComponent()
      expect(props.fetchImages).toHaveBeenCalledWith({calledFromRender: true})
    })

    it('does not display the "Load more results" button', () => {
      renderComponent()
      expect(getLoadMoreButton(/Load more results/)).not.toBeInTheDocument()
    })
  })

  describe('after updating for initial data load', () => {
    beforeEach(() => {
      renderComponent()
      props.fetchImages = jest.fn()
      props.images.isLoading = true
      renderComponent()
    })

    it('indicates the initial load in progress', () => {
      expect(getInitialLoadIndicator()).toBeInTheDocument()
    })

    it('does not call the .fetchImages prop again', () => {
      expect(props.fetchImages).toHaveBeenCalledTimes(0)
    })

    it('does not display the "Load more results" button', () => {
      renderComponent()
      expect(getLoadMoreButton(/Load more results/)).not.toBeInTheDocument()
    })
  })

  describe('after initial load resolves with images', () => {
    beforeEach(() => {
      renderComponent()
      props.images.isLoading = true
      renderComponent()
      props.images.isLoading = false
      props.images.records = [
        buildImage(0, 'example_1.png', 100, 200),
        buildImage(1, 'example_2.png', 101, 201),
        buildImage(2, 'example_3.png', 102, 202)
      ]
    })

    it('removes the initial load indicator', () => {
      renderComponent()
      expect(getInitialLoadIndicator()).not.toBeInTheDocument()
    })

    it('displays the loaded images', () => {
      renderComponent()
      expect(getImages()).toHaveLength(3)
    })

    it('displays the "Load more results" button when more results can be loaded', () => {
      props.images.hasMore = true
      renderComponent()
      expect(getLoadMoreButton(/Load more results/)).toBeInTheDocument()
    })

    it('does not display the "Load more results" button when no more results can be loaded', () => {
      props.images.hasMore = false
      renderComponent()
      expect(getLoadMoreButton(/Load more results/)).not.toBeInTheDocument()
    })

    it('does not change focus', () => {
      const previousActiveElement = document.activeElement
      props.images.hasMore = false
      renderComponent()
      expect(document.activeElement).toEqual(previousActiveElement)
    })
  })

  describe('after updating to load additional images', () => {
    beforeEach(() => {
      // Initial render
      renderComponent()

      // Begin initial load after mounting
      props.images.isLoading = true
      renderComponent()

      // Initial load completes
      props.images = {
        hasMore: true,
        isLoading: false,
        records: [
          buildImage(0, 'example_1.png', 100, 200),
          buildImage(1, 'example_2.png', 101, 201),
          buildImage(2, 'example_3.png', 102, 202)
        ]
      }
      renderComponent()

      // Load more
      props.images.isLoading = true
      renderComponent()
    })

    it('does not display the initial load indicator', () => {
      renderComponent()
      expect(getInitialLoadIndicator()).not.toBeInTheDocument()
    })

    it('displays all previously-loaded images', () => {
      renderComponent()
      expect(getImages()).toHaveLength(3)
    })

    it('displays the "Loading..." button', () => {
      expect(getLoadMoreButton(/Loading.../)).toBeInTheDocument()
    })
  })

  describe('after additional load resolves with images', () => {
    beforeEach(() => {
      // Initial render
      renderComponent()

      // Begin initial load after mounting
      props.images.isLoading = true
      renderComponent()

      // Initial load completes
      props.images = {
        hasMore: true,
        isLoading: false,
        records: [
          buildImage(0, 'example_1.png', 100, 200),
          buildImage(1, 'example_2.png', 101, 201),
          buildImage(2, 'example_3.png', 102, 202)
        ]
      }
      renderComponent()

      // Load more
      props.images.isLoading = true
      renderComponent()

      // Additional images loaded
      props.images = {
        hasMore: true,
        isLoading: false,
        records: [
          ...props.images.records,
          buildImage(3, 'example_4.png', 103, 203)
        ]
      }
    })

    it('displays all previously- and new-loaded images', () => {
      renderComponent()
      expect(getImages()).toHaveLength(4)
    })

    it('moves focus from the "Load more results" button to the last image', () => {
      fireEvent.focus(getLoadMoreButton(/Loading.../))
      renderComponent()
      const $images = getImages()
      const $lastImage = $images[$images.length - 1]
      expect(document.activeElement.contains($lastImage)).toEqual(true)
    })

    it('does not change focus when the user has changed focus', () => {
      const previousActiveElement = document.activeElement
      fireEvent.focus(getImages()[1])
      renderComponent()
      expect(document.activeElement).toEqual(previousActiveElement)
    })

    it('displays the "Load more results" button when more results can be loaded', () => {
      props.images.hasMore = true
      renderComponent()
      expect(getLoadMoreButton(/Load more results/)).toBeInTheDocument()
    })

    it('does not display the "Load more results" button when no more results can be loaded', () => {
      props.images.hasMore = false
      renderComponent()
      expect(getLoadMoreButton(/Load more results/)).not.toBeInTheDocument()
    })
  })
})
