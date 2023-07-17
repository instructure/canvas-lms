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

export default {
  lib: {
    Base: {},
    WordArray: {},
    BufferedBlockAlgorithm: {},
    Hasher: {},
    Cipher: {},
    StreamCipher: {},
    BlockCipherMode: {},
    BlockCipher: {},
    CipherParams: {},
    SerializableCipher: {},
    PasswordBasedCipher: {},
  },

  x64: {
    Word: {},
    WordArray: {},
  },

  enc: {
    Hex: {},
    Latin1: {},
    Utf8: {parse: () => {}},
    Utf16: {},
    Utf16BE: {},
    Utf16LE: {},
    Base64: {},
    Base64url: {},
  },

  algo: {
    HMAC: {},
    MD5: {},
    SHA1: {},
    SHA224: {},
    SHA256: {},
    SHA384: {},
    SHA512: {},
    SHA3: {},
    RIPEMD160: {},

    PBKDF2: {},
    EvpKDF: {},

    AES: {},
    DES: {},
    TripleDES: {},
    Rabbit: {},
    RabbitLegacy: {},
    RC4: {},
    RC4Drop: {},
    Blowfish: {},
  },

  mode: {
    CBC: {},
    CFB: {},
    CTR: {},
    CTRGladman: {},
    ECB: {},
    OFB: {},
  },

  pad: {
    Pkcs7: {},
    AnsiX923: {},
    Iso10126: {},
    Iso97971: {},
    NoPadding: {},
    ZeroPadding: {},
  },

  format: {
    OpenSSL: {},
    Hex: {},
  },

  kdf: {
    OpenSSL: {},
  },

  MD5: {},
  HmacMD5: {},
  SHA1: {},
  HmacSHA1: {},
  SHA224: {},
  HmacSHA224: {},
  SHA256: {},
  HmacSHA256: {},
  SHA384: {},
  HmacSHA384: {},
  SHA512: {},
  HmacSHA512: {},
  SHA3: {},
  HmacSHA3: {},
  RIPEMD160: {},
  HmacRIPEMD160: {},

  PBKDF2: {},
  EvpKDF: {},

  AES: {},
  DES: {},
  TripleDES: {},
  Rabbit: {},
  RabbitLegacy: {},
  RC4: {encrypt: () => {}, decrypt: () => {}},
  RC4Drop: {encrypt: () => {}, decrypt: () => {}},
  Blowfish: {},
}
