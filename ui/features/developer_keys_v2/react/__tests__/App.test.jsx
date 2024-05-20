/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, act} from '@testing-library/react'
import App from '../App'

const makeKey = ({id, name, inherited_from = 'global', account_owns_binding = true}) => ({
  id,
  name,
  created_at: '2012-06-07T20:36:50Z',
  inherited_from,
  access_token_count: 0,
  developer_key_account_binding: {
    account_owns_binding,
    workflow_state: 'on',
  },
})

const siteAdminKeys = [
  makeKey({id: '1', name: 'Site Admin 1'}),
  makeKey({id: '2', name: 'Site Admin 2'}),
]
const parentKeys = [
  makeKey({
    id: '3',
    name: 'Parent 1',
    inherited_from: 'federated_parent',
    account_owns_binding: false,
  }),
  makeKey({
    id: '4',
    name: 'Parent 2',
    inherited_from: 'federated_parent',
    account_owns_binding: false,
  }),
]

const initialApplicationState = inheritedList => {
  return {
    createOrEditDeveloperKey: {
      isLtiKey: false,
      developerKeyCreateOrEditFailed: false,
      developerKeyCreateOrEditSuccessful: true,
      developerKeyCreateOrEditPending: false,
      developerKeyModalOpen: false,
      developerKey: {},
      editing: false,
    },
    listDeveloperKeyScopes: {
      availableScopes: {},
      listDeveloperKeyScopesPending: false,
      selectedScopes: [],
    },
    listDeveloperKeys: {
      listDeveloperKeysPending: false,
      listDeveloperKeysSuccessful: false,
      inheritedList,
      list: [],
      nextPage: 'http://...',
      inheritedNextPage: 'http://...',
      listInheritedDeveloperKeysPending: false,
      listInheritedDeveloperKeysSuccessful: false,
    },
  }
}

const renderApp = ({ENV, inheritedList, ...overrides}) => {
  const props = {
    applicationState: initialApplicationState(inheritedList),
    actions: {
      developerKeysModalOpen: () => {},
      createOrEditDeveloperKey: () => {},
      developerKeysModalClose: () => {},
      getRemainingDeveloperKeys: () => {},
      getRemainingInheritedDeveloperKeys: () => {},
      editDeveloperKey: () => {},
      listDeveloperKeyScopesSet: () => {},
      saveLtiToolConfiguration: () => {},
      ltiKeysSetLtiKey: () => {},
      resetLtiState: () => {},
      updateLtiKey: () => {},
      listDeveloperKeysReplace: () => {},
      makeVisibleDeveloperKey: () => {},
      setBindingWorkflowState: () => {},
      makeInvisibleDeveloperKey: () => {},
      activateDeveloperKey: () => {},
      deactivateDeveloperKey: () => {},
      deleteDeveloperKey: () => {},
    },
    store: {dispatch: () => {}},
    ctx: {
      params: {
        contextId: '',
      },
    },
    ...overrides,
  }

  return render(<App {...props} />)
}
describe('DeveloperKeys App', () => {
  let getByText
  let queryByText
  let getAllByRole
  let queryByTestId

  const setup = (ENV, inheritedList) => {
    const wrapper = renderApp({ENV, inheritedList})
    getByText = wrapper.getByText
    queryByText = wrapper.queryByText
    getAllByRole = wrapper.getAllByRole
    queryByTestId = wrapper.queryByTestId
    // switch to inherited tab
    act(() => getByText('Inherited').click())
  }

  describe('inherited tab', () => {
    describe('when parent keys are present', () => {
      beforeEach(() => {
        ENV = {FEATURES: {developer_key_page_checkboxes: true}}
        setup(ENV, [...parentKeys, ...siteAdminKeys])
      })

      it('renders Parent Keys heading', () => {
        expect(getByText('Consortium Parent Keys')).toBeInTheDocument()
      })

      it('renders parent keys table', () => {
        expect(getByText('Parent Inherited Developer Keys')).toBeInTheDocument()
      })

      it('renders Global Keys heading', () => {
        expect(getByText('Global Keys')).toBeInTheDocument()
      })

      it('renders row per parent key', () => {
        parentKeys.forEach(key => expect(getByText(key.name)).toBeInTheDocument())
      })

      it('does not allow parent key state toggling', () => {
        const toggles = getAllByRole('checkbox')
        parentKeys.forEach(key => {
          expect(toggles.some(t => t.name === key.id && t.disabled)).toBe(true)
        })
      })
    })

    describe('when parent keys are not present', () => {
      beforeEach(() => {
        setup({}, siteAdminKeys)
      })

      it('does not render Parent Keys heading', () => {
        expect(queryByText('Consortium Parent Keys')).not.toBeInTheDocument()
      })

      it('does not render parent keys table', () => {
        expect(queryByText('Parent Inherited Developer Keys')).not.toBeInTheDocument()
      })

      it('does not render Global Keys heading', () => {
        expect(queryByText('Global Keys')).not.toBeInTheDocument()
      })
    })
  })
})
