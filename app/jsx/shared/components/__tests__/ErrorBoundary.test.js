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

import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import ReactDOM from 'react-dom'
import ErrorBoundary from '../ErrorBoundary'
import GenericErrorPage from '../GenericErrorPage'

import $ from 'jquery'

class ThrowsErrorComponent extends React.Component {
  componentDidMount() {
    throw new Error('Monster Kill')
  }

  render() {
    return <div />
  }
}

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

const defaultGenericProps = {
  errorCategory: '404'
}

const defaultProps = () => ({
  errorComponent: <GenericErrorPage {...defaultGenericProps} />
})

describe('ErrorBoundary', () => {
  test('renders the component', () => {
    ReactDOM.render(
      <ErrorBoundary {...defaultProps()}>
        <div>Making sure this works</div>
      </ErrorBoundary>,
      document.getElementById('fixtures')
    )
    const element = $('#fixtures')
    expect(element.text()).toEqual('Making sure this works')
  })

  test('renders the component when error is thrown', () => {
    // eslint-disable-next-line  no-undef
    spyOn(console, 'error') // In tests that you expect errors
    ReactDOM.render(
      <ErrorBoundary errorComponent={<div>Making sure this does not work</div>}>
        <div>
          <div>Making sure this works</div>
          <ThrowsErrorComponent />
        </div>
      </ErrorBoundary>,
      document.getElementById('fixtures')
    )

    const element = $('#fixtures')
    expect(element.text()).toEqual('Making sure this does not work')
  })
})
