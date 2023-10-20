// Copyright (C) 2021 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import getRCSProps from '../getRCSProps'

describe('getRCSProps', () => {
  it('returns null if there is no context_asset_string in the environment', () => {
    expect(getRCSProps()).toBeNull()
  })

  it('returns user context if cannot upload files', () => {
    ENV = {
      ...ENV,
      current_user_id: 'user_id',
      RICH_CONTENT_CAN_UPLOAD_FILES: false,
      context_asset_string: 'course_1',
    }
    expect(getRCSProps()).toMatchObject({
      contextId: 'user_id',
      contextType: 'user',
    })
  })

  it('returns user context contextType is "account"', () => {
    ENV = {
      ...ENV,
      current_user_id: 'user_id',
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      context_asset_string: 'account_1',
    }
    expect(getRCSProps()).toMatchObject({
      contextId: 'user_id',
      contextType: 'user',
    })
  })

  it('returns user host and jwt from ENV', () => {
    ENV = {
      ...ENV,
      current_user_id: 'user_id',
      context_asset_string: 'course_1',
      JWT: 'the jwt',
      RICH_CONTENT_APP_HOST: 'the.host',
    }
    expect(getRCSProps()).toMatchObject({
      jwt: 'the jwt',
      host: 'the.host',
    })
  })

  it('returns containing context form context_asset_string', () => {
    ENV = {
      ...ENV,
      current_user_id: 'user_id',
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      context_asset_string: 'course_1',
    }
    expect(getRCSProps()).toMatchObject({
      containingContext: {
        contextType: 'course',
        contextId: '1',
        userId: 'user_id',
      },
      contextType: 'course',
      contextId: '1',
    })
  })

  it('returns other constants from the environment', () => {
    ENV = {
      ...ENV,
      current_user_id: 'user_id',
      context_asset_string: 'course_1',
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      RICH_CONTENT_FILES_TAB_DISABLED: false,
      active_brand_config_json_url: 'http://the.theme.here/',
      DEEP_LINKING_POST_MESSAGE_ORIGIN: 'https://canvas.instructure.com',
      FEATURES: {},
    }
    expect(getRCSProps()).toMatchObject({
      canUploadFiles: true,
      filesTabDisabled: false,
      themeUrl: 'http://the.theme.here/',
    })
  })

  it('returns the refreshToken function', () => {
    ENV = {
      ...ENV,
      current_user_id: 'user_id',
      context_asset_string: 'course_1',
    }
    expect(typeof getRCSProps().refreshToken).toEqual('function')
  })
})
