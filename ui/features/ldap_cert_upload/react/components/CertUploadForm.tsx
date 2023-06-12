// @ts-nocheck
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

import React, {MouseEventHandler, useEffect, useState} from 'react'
import {FileDrop} from '@instructure/ui-file-drop'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconUploadSolid, IconCertifiedLine, IconTrashLine} from '@instructure/ui-icons'
import {isCa, parseCertificate, withinValidityPeriod} from '../../utils/certUtils'
import {X509Certificate} from '@peculiar/x509'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('ldapInternalCaUpload')

const dateFormatter = new Intl.DateTimeFormat(ENV?.LOCALE || navigator.language, {
  dateStyle: 'full',
  timeStyle: 'long',
})

const ACCEPTED_TYPES = [
  // mime types
  'application/x-pkcs7-certificates',
  'application/x-pkcs7-mime',
  'application/x-x509-ca-cert',
  // file extensions
  'p7b',
]

export type CertUploadFormProps = {
  inputField: HTMLInputElement // the element where the PEM-encoded cert should be read/written
}

export const CertUploadForm = ({inputField}: CertUploadFormProps) => {
  const [cert, setCert] = useState(() =>
    inputField.value ? new X509Certificate(inputField.value) : null
  )
  const [errors, setErrors] = useState<string[]>([])

  // update the input field if a new certificate is selected
  useEffect(() => {
    const pemCert = cert?.toString('pem') || ''

    if (inputField.value !== pemCert) {
      inputField.value = pemCert
    }
  }, [cert, inputField.value])

  // check certificate for minimum level of validity (is a CA, not expired)
  useEffect(() => {
    if (cert) {
      const newErrors: string[] = []

      if (!isCa(cert)) newErrors.push(I18n.t('Certificate is not a CA'))

      if (!withinValidityPeriod(cert))
        newErrors.push(I18n.t('Certificate is expired or not yet valid'))

      if (cert.privateKey) newErrors.push(I18n.t('Private key is present in certificate file'))

      setErrors(newErrors)
    } else {
      setErrors([])
    }
  }, [cert])

  // if errors are present, mark input invalid to prevent form submission
  useEffect(() => {
    inputField.setCustomValidity(errors.join(', '))
    inputField.reportValidity()
  }, [errors, inputField])

  const handleCertCleared: MouseEventHandler = event => {
    setCert(null)
    event.preventDefault()
  }

  return (
    <div>
      <FileDrop
        accept={ACCEPTED_TYPES.join(',')}
        onDropAccepted={([file]) => {
          parseCertificate(file)
            .then(setCert)
            .catch(() => setErrors([I18n.t('Unable to parse certificate')]))
        }}
        onDropRejected={() => setErrors([I18n.t('Unable to parse certificate')])}
        renderLabel={
          <View
            background="secondary"
            as="div"
            textAlign="center"
            padding={cert ? 'medium' : 'x-large large'}
          >
            {cert ? (
              <div>
                <Flex textAlign="start" justifyItems="space-around">
                  <IconCertifiedLine size="medium" color="success" />
                  <div>
                    <dl>
                      <dt>{I18n.t('Subject Name')}</dt>
                      <dd>{cert.subject}</dd>

                      <dt>{I18n.t('Not Valid Before')}</dt>
                      <dd>{dateFormatter.format(cert.notBefore)}</dd>

                      <dt>{I18n.t('Not Valid After')}</dt>
                      <dd>{dateFormatter.format(cert.notAfter)}</dd>
                    </dl>
                  </div>
                </Flex>
                <Text
                  size="small"
                  as="div"
                  dangerouslySetInnerHTML={{
                    __html: I18n.t('Drag and drop or *browse your files* to replace', {
                      wrapper: '<span style="color: var(--ic-brand-primary)">$1</span>',
                    }),
                  }}
                />
                <br />
                <Button renderIcon={IconTrashLine} onClick={handleCertCleared} size="small">
                  {I18n.t('Remove certificate')}
                </Button>
              </div>
            ) : (
              <>
                <IconUploadSolid />
                <Text as="div" weight="bold">
                  {I18n.t('Upload internal root CA')}
                </Text>
                <Text
                  dangerouslySetInnerHTML={{
                    __html: I18n.t('Drag and drop or *browse your files*', {
                      wrapper: '<span style="color: var(--ic-brand-primary)">$1</span>',
                    }),
                  }}
                />
                <Text size="small" as="div" lineHeight="double">
                  {I18n.t('A single certificate file')}
                </Text>
              </>
            )}
          </View>
        }
        messages={errors.map(error => ({text: error, type: 'error'}))}
        margin="x-small"
      />
    </div>
  )
}
