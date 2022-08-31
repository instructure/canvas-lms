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

import {addAccountsToTree} from '../utils'
import {
  RESPONSE_ACCOUNT_1,
  RESPONSE_ACCOUNT_3,
  RESPONSE_ACCOUNT_4,
  COLLECTION_ACCOUNT_1,
  COLLECTION_ACCOUNT_1_4,
  COLLECTION_ACCOUNT_3
} from './fixtures'

describe('utils', () => {
  describe('addAccountsToTree', () => {
    it('converts raw initial json into a new Collection', () => {
      const collections = addAccountsToTree(RESPONSE_ACCOUNT_1, {}, 1)
      expect(collections).toEqual(COLLECTION_ACCOUNT_1)
    })

    it('merges new accounts into existing Collection', () => {
      const collections = addAccountsToTree(RESPONSE_ACCOUNT_4, COLLECTION_ACCOUNT_1, 1)
      expect(collections).toEqual(COLLECTION_ACCOUNT_1_4)
    })

    it('creates a collection even if the requested account has no subaccounts', () => {
      const collections = addAccountsToTree(RESPONSE_ACCOUNT_3, {}, 3)
      expect(collections).toEqual(COLLECTION_ACCOUNT_3)
    })
  })
})
