/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import $ from 'jquery'
import 'jquery-migrate'
import DeveloperKey from '../DeveloperKey'

describe('DeveloperKey', () => {
  const defaultProps = {
    developerKey: {
      access_token_count: 77,
      account_name: 'bob account',
      api_key: 'rYcJ7LnUbSAuxiMh26tXTSkaYWyfRPh2lr6FqTLqx0FRsmv44EVZ2yXC8Rgtabc3',
      created_at: '2018-02-09T20:36:50Z',
      email: 'bob@myemail.com',
      icon_url: 'http://my_image.com',
      id: '10000000000004',
      last_used_at: '2018-06-07T20:36:50Z',
      name: 'Atomic fireball',
      notes: 'all the notas',
      redirect_uri: 'http://my_redirect_uri.com',
      redirect_uris: '',
      user_id: '53532',
      user_name: 'billy bob',
      vendor_code: 'b3w9w9bf',
      workflow_state: 'active',
      visible: false,
    },
    store: {
      dispatch: jest.fn(),
    },
    actions: {
      makeVisibleDeveloperKey: jest.fn(),
      makeInvisibleDeveloperKey: jest.fn(),
      activateDeveloperKey: jest.fn(),
      deactivateDeveloperKey: jest.fn(),
      deleteDeveloperKey: jest.fn(),
      editDeveloperKey: jest.fn(),
      developerKeysModalOpen: jest.fn(),
      setBindingWorkflowState: jest.fn(),
      ltiKeysSetLtiKey: jest.fn(),
    },
    ctx: {params: {contextId: 'context'}},
    onDelete: jest.fn(),
  }

  const renderComponent = (props = defaultProps) => {
    return render(
      <table>
        <tbody>
          <DeveloperKey {...props} />
        </tbody>
      </table>,
    )
  }

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
  })

  afterEach(() => {
    document.getElementById('fixtures').innerHTML = ''
    $('#ui-datepicker-div').empty()
  })

  it('displays developer name', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('developer-name')).toHaveTextContent('Atomic fireball')
  })

  it('displays "Unnamed Tool" when name is null', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, name: null},
    }
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('developer-name')).toHaveTextContent('Unnamed Tool')
  })

  it('displays "Unnamed Tool" when name is empty string', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, name: ''},
    }
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('developer-name')).toHaveTextContent('Unnamed Tool')
  })

  it('displays email', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('user-email')).toHaveTextContent('bob@myemail.com')
  })

  it('displays "No Email" when userName is null and email missing', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, user_name: null, email: null},
    }
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('user-email')).toHaveTextContent('No Email')
  })

  it('displays "No Email" when userName is empty string and email is missing', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, user_name: '', email: null},
    }
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('user-email')).toHaveTextContent('No Email')
  })

  it('displays an image when name is present', () => {
    const {container} = renderComponent()
    expect(container.querySelector('img')).toBeInTheDocument()
  })

  it('displays an img box when name is null', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, name: null},
    }
    const {container} = renderComponent(props)
    expect(container.querySelector('img')).toBeInTheDocument()
  })

  it('includes a user link when user_id is present', () => {
    const {container} = renderComponent()
    const link = container.querySelector('a')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', '/users/53532')
  })

  it('does not include a user link when user_id is null', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, user_id: null},
    }
    const {container} = renderComponent(props)
    expect(container.querySelector('a')).not.toBeInTheDocument()
  })

  it('displays redirect URI', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('redirect-uri')).toHaveTextContent('URI: http://my_redirect_uri.com')
  })

  it('does not display redirect URI when redirect_uri is null', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, redirect_uri: null},
    }
    const {container} = renderComponent(props)
    const redirectUriDiv = container.querySelector('[data-testid="redirect-uri"] div')
    expect(redirectUriDiv).toBeNull()
  })

  it('displays last used date', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('last-used')).toHaveTextContent('Last Used: 2018-06-07T20:36:50Z')
  })

  it('displays "Never" when last_used_at is null', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, last_used_at: null},
    }
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('last-used')).toHaveTextContent('Last Used: Never')
  })

  it('displays developer key state control for site admin keys', () => {
    const props = {
      ...defaultProps,
      ctx: {params: {contextId: 'site_admin'}},
    }
    const {container} = renderComponent(props)
    expect(container).toHaveTextContent('Key state for the current account')
  })

  it('displays "No Email" when email is missing', () => {
    const props = {
      ...defaultProps,
      developerKey: {...defaultProps.developerKey, email: null},
    }
    const {getByTestId} = renderComponent(props)
    expect(getByTestId('user-email')).toHaveTextContent('No Email')
  })

  describe('when inherited is true', () => {
    const inheritedProps = {
      ...defaultProps,
      inherited: true,
    }

    it('does not display user info', () => {
      const {queryByTestId} = renderComponent(inheritedProps)
      expect(queryByTestId('user-email')).not.toBeInTheDocument()
    })

    it('does not display redirect URI', () => {
      const {queryByTestId} = renderComponent(inheritedProps)
      expect(queryByTestId('redirect-uri')).not.toBeInTheDocument()
    })

    it('does not display access token info', () => {
      const {queryByTestId} = renderComponent(inheritedProps)
      expect(queryByTestId('access-token-count')).not.toBeInTheDocument()
      expect(queryByTestId('created-at')).not.toBeInTheDocument()
      expect(queryByTestId('last-used')).not.toBeInTheDocument()
    })

    it('does not display developer key secret', () => {
      const {container} = renderComponent(inheritedProps)
      expect(container).not.toHaveTextContent(defaultProps.developerKey.api_key)
    })
  })

  it('shows API key when clicking show key button', async () => {
    const {getByTestId, getByText} = renderComponent()
    const showKeyButton = getByTestId('show-key')
    fireEvent.click(showKeyButton)
    await waitFor(() => {
      expect(getByText(defaultProps.developerKey.api_key)).toBeInTheDocument()
    })
  })
})
