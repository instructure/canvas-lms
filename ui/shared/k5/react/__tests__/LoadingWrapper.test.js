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

import React from 'react'
import {render} from '@testing-library/react'
import LoadingWrapper from '../LoadingWrapper'
import {View} from '@instructure/ui-view'

describe('LoadingWrapper', () => {
  const getProps = (props = {}) => ({
    id: 'component-to-load',
    skeletonsCount: 1,
    screenReaderLabel: 'Loading content...',
    width: '10em',
    height: '5em',
    isLoading: false,
    ...props
  })

  it('renders the number of specified skeletons', () => {
    const {getAllByText} = render(
      <LoadingWrapper {...getProps({skeletonsCount: 3, isLoading: true})} />
    )
    const skeletons = getAllByText('Loading content...')
    expect(skeletons.length).toBe(3)
  })

  it('renders the child component when loaded', () => {
    const {getByText, rerender} = render(<LoadingWrapper {...getProps({isLoading: true})} />)
    expect(getByText('Loading content...')).toBeInTheDocument()
    rerender(
      <LoadingWrapper {...getProps()}>
        <View>This is a child component</View>
      </LoadingWrapper>
    )
    expect(getByText('This is a child component')).toBeInTheDocument()
  })

  it('sets the width, height and screenReaderLabel to the skeleton', () => {
    const {getByText, getByTestId} = render(<LoadingWrapper {...getProps({isLoading: true})} />)
    const skeletonWrapper = getByTestId('skeleton-wrapper')
    expect(getByText('Loading content...')).toBeInTheDocument()
    expect(skeletonWrapper.style.width).toBe('10em')
    expect(skeletonWrapper.style.height).toBe('5em')
  })

  it('renders custom skeletons if renderCustomSkeleton is provided', () => {
    const renderCustomSkeleton = jest.fn(props => <View {...props}>Custom Loading...</View>)
    const {getAllByText} = render(
      <LoadingWrapper
        {...getProps({
          isLoading: true,
          skeletonsCount: 3,
          renderCustomSkeleton
        })}
      />
    )
    expect(renderCustomSkeleton).toHaveBeenCalledTimes(3)
    const customSkeletons = getAllByText('Custom Loading...')
    expect(customSkeletons.length).toBe(3)
  })

  it('passes the skeletons to renderSkeletonsContainer when provided and shows it when loading', () => {
    const renderSkeletonsContainer = jest.fn(c => <div className="container">{c}</div>)
    const {getByText, container, rerender} = render(
      <LoadingWrapper {...getProps({isLoading: true, renderSkeletonsContainer})} />
    )
    expect(container.querySelector('div.container')).toBeInTheDocument()
    rerender(
      <LoadingWrapper {...getProps({renderSkeletonsContainer})}>
        <View>This is the loaded child component</View>
      </LoadingWrapper>
    )
    expect(renderSkeletonsContainer).toHaveBeenCalledTimes(1)
    expect(container.querySelector('div.container')).not.toBeInTheDocument()
    expect(getByText('This is the loaded child component')).toBeInTheDocument()
  })

  it('passes the loaded content to renderLoadedContainer when provided and shows it when finish loading', () => {
    const renderLoadedContainer = jest.fn(content => <div className="container">{content}</div>)
    const {getByText, container, rerender} = render(
      <LoadingWrapper {...getProps({isLoading: true, renderLoadedContainer})} />
    )
    expect(container.querySelector('div.container')).not.toBeInTheDocument()
    rerender(
      <LoadingWrapper {...getProps({renderLoadedContainer})}>
        <View>This is the loaded child component</View>
      </LoadingWrapper>
    )
    expect(renderLoadedContainer).toHaveBeenCalledTimes(1)
    expect(container.querySelector('div.container')).toBeInTheDocument()
    expect(getByText('This is the loaded child component')).toBeInTheDocument()
  })
})
