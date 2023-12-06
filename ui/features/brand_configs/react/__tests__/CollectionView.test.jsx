/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import fetchMock from 'fetch-mock'
import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {within} from '@testing-library/dom'
import Subject from '../CollectionView'
import {submitHtmlForm} from '@canvas/theme-editor/submitHtmlForm'

jest.mock('@canvas/theme-editor/submitHtmlForm', () => ({
  __esModule: true,
  submitHtmlForm: jest.fn(),
}))

const OUR_ACCOUNT_ID = '123'
const ACTIVE_BASIS = {
  name: 'Account-shared Theme',
  md5: '00112233445566778899aabbccddeeff',
}
const DELETABLE_ID = 9847
const DELETABLE_BASIS = {
  name: 'Deletable Theme',
  md5: '01234567012345670123456701234567',
}

const props = {
  sharedBrandConfigs: [
    {
      account_id: null,
      name: 'Canned Template Theme',
      id: 128,
      brand_config: {
        md5: '001122334455667788990022446688aa',
        variables: {
          foo: '#123',
        },
      },
    },
    {
      account_id: null,
      name: 'Another Canned Template Theme',
      id: 127,
      brand_config: {
        md5: '00112233445566778899001122334455',
        variables: {
          foo: '#123',
        },
      },
    },
    {
      account_id: OUR_ACCOUNT_ID,
      name: ACTIVE_BASIS.name,
      id: 123,
      brand_config: {
        md5: ACTIVE_BASIS.md5,
        variables: {
          foo: '#123',
        },
      },
    },
    {
      account_id: OUR_ACCOUNT_ID,
      name: DELETABLE_BASIS.name,
      id: DELETABLE_ID,
      brand_config: {
        md5: DELETABLE_BASIS.md5,
        variables: {
          foo: '#fff',
        },
      },
    },
  ],
  activeBrandConfig: {
    md5: ACTIVE_BASIS.md5,
    variables: {},
  },
  accountID: OUR_ACCOUNT_ID,
  brandableVariableDefaults: {
    foo: {
      default: '#321',
      type: 'color',
      variable_name: 'foo',
    },
    otherFoo: {
      default: '$foo',
      type: 'color',
      variable_name: 'Other Foo',
    },
  },
  baseBrandableVariables: {
    foo: 'red',
  },
}

describe('CollectionView', () => {
  const deleteURL = new RegExp('/api/v1/shared_brand_configs/(.+)')
  const {location: savedLocation} = window

  beforeEach(() => {
    fetchMock.delete(deleteURL, {})
    // JS DOM doesn't implement location.reload
    delete window.location
    window.location = {reload: jest.fn()}
  })

  afterEach(() => {
    fetchMock.restore()
    window.location = savedLocation
    jest.clearAllMocks()
  })

  it('renders', () => {
    const {container} = render(<Subject {...props} />)
    const title = container.querySelector('h1')
    expect(title.innerHTML).toBe('Themes')
  })

  it('always shows the default theme in the Templates', () => {
    const {getByTestId} = render(<Subject {...props} />)
    const templates = getByTestId('container-templates-section')
    const cardButtons = within(templates).getAllByTestId('themecard-name-button')
    const found = cardButtons.some(card => {
      return !!within(card).queryByText('Default Template')
    })
    expect(found).toBe(true)
  })

  it('shows cards in Templates for all sharedBrandConfigs with null account', () => {
    const globalConfigNames = props.sharedBrandConfigs
      .filter(c => c.account_id === null)
      .map(c => c.name)
    const {getByTestId} = render(<Subject {...props} />)
    const templates = getByTestId('container-templates-section')
    const buttons = within(templates).getAllByTestId('themecard-name-button')
    expect(globalConfigNames.every(c => buttons.some(cc => within(cc).queryByText(c)))).toBe(true)
  })

  it('shows cards in My Themes for all sharedBrandConfigs that have my account', () => {
    const localConfigNames = props.sharedBrandConfigs
      .filter(c => c.account_id === props.accountID)
      .map(c => c.name)
    const {getByTestId} = render(<Subject {...props} />)
    const templates = getByTestId('container-mythemes-section')
    const buttons = within(templates).getAllByTestId('themecard-name-button')
    expect(localConfigNames.every(c => buttons.some(cc => within(cc).queryByText(c)))).toBe(true)
  })

  it('shows the activeBrandConfig even when its md5 is not in the list of shared ones', () => {
    const activeBrandConfig = {
      md5: '43214321432143214321432143124312',
      name: 'Very Special',
      variables: {},
    }
    const newProps = {...props, activeBrandConfig}
    const {getAllByTestId} = render(<Subject {...newProps} />)
    const cardButtons = getAllByTestId('themecard-name-button')
    // should be two extra ones (the Default Template and the new activeBrandConfig)
    expect(cardButtons).toHaveLength(props.sharedBrandConfigs.length + 2)
    expect(cardButtons.find(card => within(card).queryByText('Very Special'))).toBeDefined()
  })

  it('shows the New Theme button', () => {
    const {getByTestId} = render(<Subject {...props} />)
    expect(getByTestId('new-theme-button')).toBeInTheDocument()
  })

  it('shows all possible things to base a new theme on when New Theme is clicked', () => {
    const names = props.sharedBrandConfigs.map(c => c.name)
    names.unshift('Default Template')
    const {getByTestId, getAllByTestId} = render(<Subject {...props} />)
    const newThemeButton = getByTestId('new-theme-button')
    fireEvent.click(newThemeButton)
    const menuItems = getAllByTestId('new-theme-menu-item')
    expect(names.every(name => menuItems.some(item => within(item).queryByText(name)))).toBe(true)
  })

  it('submits the right form to create a new theme when basis is the active config', () => {
    const {getByTestId, getAllByTestId} = render(<Subject {...props} />)
    const newThemeButton = getByTestId('new-theme-button')
    fireEvent.click(newThemeButton)
    const menuItems = getAllByTestId('new-theme-menu-item')
    const basis = menuItems.find(item => within(item).queryByText(ACTIVE_BASIS.name))
    expect(basis).toBeDefined()
    fireEvent.click(basis)
    expect(submitHtmlForm).toHaveBeenCalledWith(
      `/accounts/${OUR_ACCOUNT_ID}/brand_configs/save_to_user_session`,
      'POST',
      undefined
    )
  })

  it('submits the right form to create a new theme when basis is not the active config', () => {
    const {getByTestId, getAllByTestId} = render(<Subject {...props} />)
    const newThemeButton = getByTestId('new-theme-button')
    fireEvent.click(newThemeButton)
    const menuItems = getAllByTestId('new-theme-menu-item')
    const basis = menuItems.find(item => within(item).queryByText(DELETABLE_BASIS.name))
    expect(basis).toBeDefined()
    fireEvent.click(basis)
    expect(submitHtmlForm).toHaveBeenCalledWith(
      `/accounts/${OUR_ACCOUNT_ID}/brand_configs/save_to_user_session`,
      'POST',
      DELETABLE_BASIS.md5
    )
  })

  it('does not allow system themes to be deleted', () => {
    const {getByTestId} = render(<Subject {...props} />)
    const templates = getByTestId('container-templates-section')
    const cardButtons = within(templates).queryAllByTestId('themecard-delete-button')
    expect(cardButtons).toHaveLength(0)
  })

  it('allows my themes to be deleted except the active one', () => {
    const {getByTestId} = render(<Subject {...props} />)
    const templates = getByTestId('container-mythemes-section')
    const cardButtons = within(templates).queryAllByTestId('themecard-delete-button')
    expect(cardButtons).toHaveLength(1) // not the active one, only the other one
  })

  it('allows the active theme to be deleted if multiple themes reflect the active one', () => {
    const dupOfActive = {
      account_id: OUR_ACCOUNT_ID,
      name: 'Duplicate of Account-shared Theme',
      id: 345,
      brand_config: {
        md5: ACTIVE_BASIS.md5,
        variables: {
          foo: '#123',
        },
      },
    }
    const sharedBrandConfigs = [...props.sharedBrandConfigs, dupOfActive]
    const newProps = {...props, sharedBrandConfigs}
    const {getByTestId} = render(<Subject {...newProps} />)
    const templates = getByTestId('container-mythemes-section')
    const cardButtons = within(templates).queryAllByTestId('themecard-delete-button')
    expect(cardButtons).toHaveLength(3) // BOTH the active and deletable, plus the dup
  })

  it('submits the right form to edit an existing theme', () => {
    const {getAllByTestId} = render(<Subject {...props} />)
    const cardButtons = getAllByTestId('themecard-name-button')
    const card = cardButtons.find(c => within(c).queryByText(DELETABLE_BASIS.name))
    fireEvent.click(card)
    expect(submitHtmlForm).toHaveBeenCalledWith(
      `/accounts/${OUR_ACCOUNT_ID}/brand_configs/save_to_user_session`,
      'POST',
      DELETABLE_BASIS.md5
    )
  })

  it('submits the right form to edit the active theme', () => {
    const {getAllByTestId} = render(<Subject {...props} />)
    const cardButtons = getAllByTestId('themecard-name-button')
    const card = cardButtons.find(c => within(c).queryByText(ACTIVE_BASIS.name))
    fireEvent.click(card)
    expect(submitHtmlForm).toHaveBeenCalledWith(
      `/accounts/${OUR_ACCOUNT_ID}/brand_configs/save_to_user_session`,
      'POST',
      undefined
    )
  })

  // Note that we've carefully set up the test props so that exactly one
  // brandConfig is deletable. Because we use getByText here, if that
  // becomes no longer true, this test will fail.
  it('makes the correct DELETE API call on a deletion', async () => {
    const {getByText, getByLabelText} = render(<Subject {...props} />)
    const deleteButton = getByText('Delete theme').closest('button')
    fireEvent.click(deleteButton)
    const deleteConfirmModal = getByLabelText('Delete Theme?')
    const confirmButton = within(deleteConfirmModal).getByText('Delete').closest('button')
    fireEvent.click(confirmButton)
    await fetchMock.flush(false)
    expect(fetchMock.done()).toBe(true)
    const callMatch = fetchMock.lastCall(deleteURL)[0].match(deleteURL)
    expect(parseInt(callMatch[1], 10)).toBe(DELETABLE_ID)
  })

  it('does not make any DELETE API call when the delete is canceled', async () => {
    const {getByText, getByLabelText} = render(<Subject {...props} />)
    const deleteButton = getByText('Delete theme').closest('button')
    fireEvent.click(deleteButton)
    const deleteConfirmModal = getByLabelText('Delete Theme?')
    const confirmButton = within(deleteConfirmModal).getByText('Cancel').closest('button')
    fireEvent.click(confirmButton)
    await fetchMock.flush(false)
    expect(fetchMock.called(deleteURL)).toBe(false)
  })
})
