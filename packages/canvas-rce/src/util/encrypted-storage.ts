/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import CryptoES from 'crypto-es'

export default class EncryptedStorage {
  passphrase

  constructor(passphrase: string) {
    this.passphrase = CryptoES.enc.Utf8.parse(passphrase)
  }

  setItem(key: string, content: string) {
    return this.errorHandlerWrapper(() => {
      // If passphrase is present, encrypt string and JSON stringify
      let encrypted
      if (this.passphrase) {
        encrypted = CryptoES.RC4.encrypt(content, this.passphrase, {
          mode: CryptoES.mode.CFB,
          padding: CryptoES.pad.AnsiX923,
        }).toString()
      }

      const data = JSON.stringify({autosaveTimestamp: new Date().getTime(), content: encrypted})
      return window.localStorage.setItem(key, data)
    })
  }

  getItem(key: string) {
    return this.errorHandlerWrapper(() => {
      const data = window.localStorage.getItem(key)
      if (!data) {
        return data
      }
      // If passphrase is present, parse JSON and decrypt string
      if (this.passphrase) {
        const parsedData = JSON.parse(data)
        parsedData.content = CryptoES.RC4.decrypt(parsedData.content, this.passphrase, {
          mode: CryptoES.mode.CFB,
          padding: CryptoES.pad.AnsiX923,
        })
        parsedData.content = parsedData.content.toString(CryptoES.enc.Utf8)
        return parsedData
      }
    })
  }

  key(index: number) {
    return this.errorHandlerWrapper(() => window.localStorage.key(index))
  }

  removeItem(key: string) {
    return this.errorHandlerWrapper(() => window.localStorage.removeItem(key))
  }

  errorHandlerWrapper = <T>(callback: () => T) => {
    try {
      return callback()
    } catch (error) {
      console.error('error', error)
      return null
    }
  }
}
