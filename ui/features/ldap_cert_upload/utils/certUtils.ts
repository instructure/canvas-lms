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

import {
  BasicConstraintsExtension,
  X509Certificate,
  X509Certificates,
  PemConverter,
} from '@peculiar/x509'
import {AsnSchemaValidationError} from '@peculiar/asn1-schema'

export const parseCertificate = async (file: File): Promise<X509Certificate> => {
  let result: string | ArrayBuffer = (await file.text()).replace(/\r/g, '') // CRLF -> LF

  if (!PemConverter.isPem(result)) result = await file.arrayBuffer()

  try {
    // try parsing as pkcs7 first
    return new X509Certificates(result)[0]
  } catch (e) {
    if (!(e instanceof AsnSchemaValidationError)) throw e

    // not pkcs7; parse as x509 cert instead
    return new X509Certificate(result)
  }
}

export const isCa = (certificate: X509Certificate) =>
  certificate.extensions.some(
    extension =>
      extension.critical && extension instanceof BasicConstraintsExtension && extension.ca
  )

export const withinValidityPeriod = (certificate: X509Certificate) => {
  const date = new Date()

  return certificate.notBefore <= date && certificate.notAfter >= date
}
