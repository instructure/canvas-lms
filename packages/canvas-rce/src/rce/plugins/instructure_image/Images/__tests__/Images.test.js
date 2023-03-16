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
import {fireEvent, render, getByText} from '@testing-library/react'

import {buildImage} from '../../../../../rcs/fake'
import Images from '..'

describe('RCE "Images" Plugin > Images', () => {
  let component
  let props

  beforeEach(() => {
    component = null

    props = {
      fetchInitialImages: jest.fn(),
      fetchNextImages: jest.fn(),
      images: {
        course: {
          hasMore: false,
          isLoading: false,
          files: [],
        },
      },
      contextType: 'course',
      sortBy: {sort: 'alphabetical', order: 'desc'},
      searchString: 'whereami?',
      onImageEmbed() {},
      canvasOrigin: 'https://canvas.instructor.com',
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

  function getLoadingIndicator() {
    return component.queryByTitle('Loading')
  }

  function getImages() {
    return component.container.querySelectorAll('img')
  }

  function getLoadMoreButton() {
    return (
      [...component.container.querySelectorAll('button')].find(
        $button => $button.textContent.trim() === 'Load More'
      ) || null
    )
  }

  describe('upon initial render', () => {
    it('calls the .fetchInitialImages prop', () => {
      renderComponent()
      expect(props.fetchInitialImages).toHaveBeenCalledTimes(1)
      expect(props.fetchInitialImages).toHaveBeenCalledWith()
    })

    it('does not display the "Load More" button', () => {
      renderComponent()
      expect(getLoadMoreButton()).not.toBeInTheDocument()
    })
  })

  describe('after updating for initial data load', () => {
    beforeEach(() => {
      renderComponent()
      props.images[props.contextType].isLoading = true
      renderComponent()
    })

    it('indicates the initial load in progress', () => {
      expect(getLoadingIndicator()).toBeInTheDocument()
    })

    it('does not call the .fetchInitialImages prop again', () => {
      expect(props.fetchInitialImages).toHaveBeenCalledTimes(1)
    })

    it('does not display the "Load More" button', () => {
      renderComponent()
      expect(getLoadMoreButton()).not.toBeInTheDocument()
    })
  })

  describe('after initial load resolves with images', () => {
    beforeEach(() => {
      renderComponent()
      props.images[props.contextType].isLoading = true
      renderComponent()
      props.images[props.contextType].isLoading = false
      props.images[props.contextType].files = [
        buildImage(0, 'example_1.png', 100, 200),
        buildImage(1, 'example_2.png', 101, 201),
        buildImage(2, 'example_3.png', 102, 202),
      ]
    })

    it('removes the initial load indicator', () => {
      renderComponent()
      expect(getLoadingIndicator()).not.toBeInTheDocument()
    })

    it('displays the loaded images', () => {
      renderComponent()
      expect(getImages()).toHaveLength(3)
    })

    it('displays the "Load More" button when more results can be loaded', () => {
      props.images[props.contextType].hasMore = true
      renderComponent()
      expect(getLoadMoreButton()).toBeInTheDocument()
    })

    it('does not display the "Load More" button when no more results can be loaded', () => {
      props.images[props.contextType].hasMore = false
      renderComponent()
      expect(getLoadMoreButton()).not.toBeInTheDocument()
    })

    it('does not change focus', () => {
      const previousActiveElement = document.activeElement
      props.images[props.contextType].hasMore = false
      renderComponent()
      expect(document.activeElement).toEqual(previousActiveElement)
    })
  })

  describe('after inital load resolves with no images', () => {
    beforeEach(() => {
      renderComponent()
      props.images[props.contextType].isLoading = true
      renderComponent()
      props.images[props.contextType].isLoading = false
    })

    it('displays No Results message', () => {
      renderComponent()
      expect(getByText(component.container, 'No results.')).toBeInTheDocument()
      expect(getImages()).toHaveLength(0)
    })
  })
  describe('after updating to load additional images', () => {
    beforeEach(() => {
      // Initial render
      renderComponent()

      // Begin initial load after mounting
      props.images[props.contextType].isLoading = true
      renderComponent()

      // Initial load completes
      props.images[props.contextType] = {
        hasMore: true,
        isLoading: false,
        files: [
          buildImage(0, 'example_1.png', 100, 200),
          buildImage(1, 'example_2.png', 101, 201),
          buildImage(2, 'example_3.png', 102, 202),
        ],
      }
      renderComponent()
      fireEvent.focus(getLoadMoreButton())

      // Load more
      props.images[props.contextType].isLoading = true
      renderComponent()
    })

    it('displays all previously-loaded images', () => {
      renderComponent()
      expect(getImages()).toHaveLength(3)
    })

    it('displays the loading indicator', () => {
      expect(getLoadingIndicator()).toBeInTheDocument()
    })

    it('moves focus from the "Load More" button to the last image', () => {
      const $images = getImages()
      const $lastImage = $images[$images.length - 1]
      expect(document.activeElement.contains($lastImage)).toEqual(true)
    })
  })

  describe('after additional load resolves with images', () => {
    beforeEach(() => {
      // Initial render
      renderComponent()

      // Begin initial load after mounting
      props.images[props.contextType].isLoading = true
      renderComponent()

      // Initial load completes
      props.images[props.contextType] = {
        hasMore: true,
        isLoading: false,
        files: [
          buildImage(0, 'example_1.png', 100, 200),
          buildImage(1, 'example_2.png', 101, 201),
          buildImage(2, 'example_3.png', 102, 202),
        ],
      }
      renderComponent()

      // Load more
      props.images[props.contextType].isLoading = true
      renderComponent()

      // Additional images loaded
      props.images[props.contextType] = {
        hasMore: true,
        isLoading: false,
        files: [...props.images[props.contextType].files, buildImage(3, 'example_4.png', 103, 203)],
      }
    })

    it('displays all previously- and new-loaded images', () => {
      renderComponent()
      expect(getImages()).toHaveLength(4)
    })

    it('displays the "Load More" button when more results can be loaded', () => {
      props.images[props.contextType].hasMore = true
      renderComponent()
      expect(getLoadMoreButton()).toBeInTheDocument()
    })

    it('does not display the "Load More" button when no more results can be loaded', () => {
      props.images[props.contextType].hasMore = false
      renderComponent()
      expect(getLoadMoreButton()).not.toBeInTheDocument()
    })
  })
})
