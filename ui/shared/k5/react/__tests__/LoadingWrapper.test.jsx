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
    skeletonsNum: 1,
    defaultSkeletonsNum: 1,
    screenReaderLabel: 'Loading content...',
    width: '10em',
    height: '5em',
    isLoading: false,
    allowZeroSkeletons: true,
    ...props,
  })

  afterEach(() => {
    localStorage.clear()
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
    expect(skeletonWrapper).toHaveStyle('width: 10em')
    expect(skeletonWrapper).toHaveStyle('height: 5em')
  })

  it('renders custom skeletons if renderCustomSkeleton is provided', () => {
    const renderCustomSkeleton = jest.fn(props => <View {...props}>Custom Loading...</View>)
    const {getAllByText} = render(
      <LoadingWrapper
        {...getProps({
          id: 'custom-skeleton',
          isLoading: true,
          skeletonsNum: null,
          defaultSkeletonsNum: 3,
          renderCustomSkeleton,
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
    expect(renderSkeletonsContainer).toHaveBeenCalled()
    expect(container.querySelector('div.container')).toBeInTheDocument()
    rerender(
      <LoadingWrapper {...getProps({renderSkeletonsContainer})}>
        <View>This is the loaded child component</View>
      </LoadingWrapper>
    )
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

  it('renders the number of skeletons based on localstorage if the key exists', () => {
    localStorage.setItem('loading-skeletons-wrapper-num', '5')
    const {getAllByText} = render(
      <LoadingWrapper {...getProps({id: 'wrapper', defaultSkeletonsNum: 3, isLoading: true})} />
    )
    const skeletons = getAllByText('Loading content...')
    expect(skeletons.length).toBe(5)
  })

  it('renders the number of skeletons based on defaultSkeletonsNum if the key is not found in localstorage', () => {
    const {getAllByText} = render(
      <LoadingWrapper
        {...getProps({
          id: 'loading-wrapper-1',
          defaultSkeletonsNum: 5,
          skeletonsNum: null,
          isLoading: true,
        })}
      />
    )
    const skeletons = getAllByText('Loading content...')
    expect(skeletons.length).toBe(5)
  })

  it('renders 1 skeleton if allowZeroSkeletons is false and cached skeletonsNum is 0', () => {
    localStorage.setItem('loading-skeletons-wrapper-num', '0')
    const {getAllByText} = render(
      <LoadingWrapper
        {...getProps({
          id: 'wrapper',
          defaultSkeletonsNum: 5,
          skeletonsNum: null,
          allowZeroSkeletons: false,
          isLoading: true,
        })}
      />
    )
    const skeletons = getAllByText('Loading content...')
    expect(skeletons.length).toBe(1)
  })

  it('persists skeletonsNum in cache by default', () => {
    const {rerender} = render(
      <LoadingWrapper
        {...getProps({
          id: 'wrapper-1',
          skeletonsNum: null,
          isLoading: true,
        })}
      />
    )

    rerender(
      <LoadingWrapper
        {...getProps({
          id: 'wrapper-1',
          skeletonsNum: 4,
          isLoading: false,
        })}
      >
        <View>This is the loaded child component</View>
      </LoadingWrapper>
    )

    expect(window.localStorage.getItem('loading-skeletons-wrapper-1-num')).toBe('4')
  })

  it("renders the number of skeletons based on skeletonsNum and doesn't persist its value in cache if persistInCache is false", () => {
    const {getAllByText, rerender} = render(
      <LoadingWrapper
        {...getProps({
          id: 'wrapper-2',
          skeletonsNum: 3,
          allowZeroSkeletons: false,
          isLoading: true,
          persistInCache: false,
        })}
      />
    )
    const skeletons = getAllByText('Loading content...')
    expect(skeletons.length).toBe(3)

    rerender(
      <LoadingWrapper
        {...getProps({
          id: 'wrapper-2',
          skeletonsNum: 3,
          allowZeroSkeletons: false,
          isLoading: false,
          persistInCache: false,
        })}
      >
        <View>This is the loaded child component</View>
      </LoadingWrapper>
    )

    expect(window.localStorage.getItem('loading-skeletons-wrapper-2-num')).toBe(null)
  })
})
