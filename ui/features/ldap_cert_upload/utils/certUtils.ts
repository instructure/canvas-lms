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

import {BasicConstraintsExtension, X509Certificate, X509Certificates} from '@peculiar/x509'

export const parseCertificate = async (file: File): Promise<X509Certificate> => {
  const isPkcs7 = file.name.endsWith('.p7b')

  const result = (await file.text()).replace(/\r/g, '') // CRLF -> LF

  // pkcs7 certificates must use a different import strategy
  if (isPkcs7) {
    const chain = new X509Certificates()
    chain.import(result)

    return chain[0]
  } else {
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
