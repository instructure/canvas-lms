/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import actions from 'jsx/developer_keys/actions/ltiKeyActions'
import developerKeysActions from 'jsx/developer_keys/actions/developerKeysActions'
import axios from 'axios'

const dispatch = jest.fn()

beforeAll(() => {
  axios.post = jest.fn().mockResolvedValue({
    data: {tool_configuration: {settings: {test: 'config'}, developer_key_id: '1'}}
  })
})

afterAll(() => {
  axios.post.mockRestore()
})

describe('saveLtiToolConfiguration', () => {
  const save = (includeUrl = false) => {
    actions.saveLtiToolConfiguration({
      account_id: '1',
      developer_key: {name: 'test'},
      settings: {test: 'config'},
      ...(includeUrl ? {settings_url: 'test.url'} : {})
    })(dispatch)
  }

  it('sets the developer key with provided fields', () => {
    save()
    expect(dispatch).toBeCalledWith(developerKeysActions.setEditingDeveloperKey({name: 'test'}))
  })

  it('sets the tool configuration url if provided', () => {
    save(true)
    expect(dispatch).toBeCalledWith(actions.setLtiToolConfigurationUrl('test.url'))
  })

  describe('on successful response', () => {
    it('sets the tool configuration', () => {
      expect(dispatch).toBeCalledWith(actions.setLtiToolConfiguration({test: 'config'}))
    })

    it('prepends the developer key to the list', () => {
      expect(dispatch).toBeCalledWith(
        developerKeysActions.listDeveloperKeysPrepend({name: 'test', id: '1'})
      )
    })
  })
})
