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

import localforage from 'localforage'
import * as CryptoJS from 'crypto-js'

export default class EncryptedForage {
  constructor(passphrase = null) {
    this.passphrase = passphrase
  }

  setItem(key, data) {
    // If passphrase is present, JSON stringify and encrypt string
    if (this.passphrase) {
      data = CryptoJS.AES.encrypt(JSON.stringify(data), this.passphrase).toString()
    }
    return localforage.setItem(key, data)
  }

  getItem(key) {
    return localforage.getItem(key).then(data => {
      if (!data) {
        return data
      }

      // If passphrase is present, decrypt string and parse JSON
      if (this.passphrase) {
        try {
          data = CryptoJS.AES.decrypt(data, this.passphrase)
          data = data.toString(CryptoJS.enc.Utf8)
          return JSON.parse(data)
        } catch (error) {
          this.deleteAll()
          return null
        }
      }
      return data
    })
  }

  deleteItem(key) {
    return localforage.removeItem(key)
  }

  deleteAll() {
    return localforage.clear()
  }
}
