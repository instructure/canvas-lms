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

import actions from '../developerKeysActions'
import axios from '@canvas/axios'
import $ from 'jquery'

const dispatch = jest.fn()

describe('saveLtiToolConfiguration', () => {
  beforeAll(() => {
    axios.post = jest.fn().mockResolvedValue({
      data: {
        tool_configuration: {settings: {test: 'config'}, developer_key_id: '1'},
        developer_key: {id: 100000000087, name: 'test key'},
      },
    })
  })

  afterAll(() => {
    axios.post.mockRestore()
  })

  const save = async (includeUrl = false) => {
    await actions.saveLtiToolConfiguration({
      account_id: '1',
      developer_key: {name: 'test'},
      settings: {test: 'config'},
      ...(includeUrl ? {settings_url: 'test.url'} : {}),
    })(dispatch)
  }

  it('sets the developer key with provided fields', () => {
    save()
    expect(dispatch).toHaveBeenCalledWith(actions.setEditingDeveloperKey({name: 'test'}))
  })

  describe('on successful response', () => {
    it('prepends the developer key to the list', () => {
      expect(dispatch).toHaveBeenCalledWith(
        actions.listDeveloperKeysPrepend({
          id: 100000000087,
          name: 'test key',
          tool_configuration: {test: 'config'},
        })
      )
    })
  })

  describe('on error response', () => {
    const error = {
      response: {
        data: {
          errors: [
            {
              message: '["Thats no moon...its a space station."]',
            },
            {
              message: '["Its too big to be a space station!"]',
            },
          ],
        },
      },
    }

    beforeAll(() => {
      axios.post = jest.fn().mockRejectedValue(error)
      $.flashError = jest.fn()
    })

    afterAll(() => {
      axios.post.mockRestore()
    })

    it('calls flashError for each message', () => {
      return expect(
        save().finally(() => {
          expect($.flashError).toHaveBeenCalledTimes(2)
          expect(dispatch).toHaveBeenCalledWith(actions.setEditingDeveloperKey(false))
        })
      ).rejects.toEqual(error)
    })
  })
})

describe('updateLtiKey', () => {
  beforeAll(() => {
    axios.put = jest.fn().mockResolvedValue({})
  })

  afterAll(() => {
    axios.put.mockRestore()
  })

  const scopes = ['https://www.test.com/scope']
  const redirectUris = 'https://www.test.com'
  const disabledPlacements = ['account_navigation', 'course_navigaiton']
  const developerKeyId = 123
  const toolConfiguration = {}
  const customFields = 'foo=bar\r\nkey=value'
  const developerKey = {
    scopes,
    redirect_uris: redirectUris,
    name: 'Test',
    notes: 'This is a test',
    email: 'test@example.com',
    access_token_count: 1,
  }

  const update = () => {
    actions.updateLtiKey(
      developerKey,
      disabledPlacements,
      developerKeyId,
      toolConfiguration,
      customFields
    )
  }

  it('makes a request to the tool config update endpoint', () => {
    update(jest.fn())

    expect(axios.put).toHaveBeenCalledWith(
      `/api/lti/developer_keys/${developerKeyId}/tool_configuration`,
      {
        developer_key: {
          scopes,
          redirect_uris: redirectUris,
          name: developerKey.name,
          notes: developerKey.notes,
          email: developerKey.email,
        },
        tool_configuration: {
          disabled_placements: disabledPlacements,
          settings: toolConfiguration,
          custom_fields: customFields,
        },
      }
    )
  })
})
