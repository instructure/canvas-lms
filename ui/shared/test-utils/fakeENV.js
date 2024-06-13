/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

export default {
  setup(options = {}) {
    if (!window.ENV) window.ENV = {}

    window.ENV = {
      current_user_id: '1',
      current_user_roles: ['user', 'teacher', 'admin', 'student'],
      current_user_is_admin: true,
      current_user_cache_key: 'users/1-20111116001415',
      context_asset_string: 'user_1',
      domain_root_account_cache_key: 'accounts/1-20111117224337',
      context_cache_key: 'users/1-20111116001415',
      PERMISSIONS: {},
      FEATURES: {},
      ...options,
    }
  },
  teardown() {
    window.ENV = {}
  },
}
