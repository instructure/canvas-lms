/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import type {FormMessage} from '@instructure/ui-form-field'
import {Link} from '@instructure/ui-link'
import React from 'react'

const I18n = createI18nScope('new_login')

interface Props {
  onChange: (checked: boolean) => void
  checked: boolean
  isDisabled: boolean
  isRequired?: boolean
  termsOfUseUrl?: string
  privacyPolicyUrl?: string
  messages?: FormMessage[]
  onFocus?: () => void
  id: string
}

const TermsAndPolicyCheckbox = ({
  onChange,
  checked,
  isDisabled,
  isRequired,
  termsOfUseUrl,
  privacyPolicyUrl,
  messages,
  onFocus,
  id,
}: Props) => {
  if (!termsOfUseUrl && !privacyPolicyUrl) {
    return null
  }

  let translatedText = ''
  let splitText: string[] = []
  if (termsOfUseUrl && privacyPolicyUrl) {
    translatedText = I18n.t('You agree to the %{termsOfUseLink} & %{privacyPolicyLink}.', {
      termsOfUseLink: 'ZZZZ_TERMS',
      privacyPolicyLink: 'ZZZZ_PRIVACY',
    })
    splitText = translatedText.split(/ZZZZ_TERMS|ZZZZ_PRIVACY/)
  } else if (termsOfUseUrl) {
    translatedText = I18n.t('You agree to the %{termsOfUseLink}.', {
      termsOfUseLink: 'ZZZZ_TERMS',
    })
    splitText = translatedText.split(/ZZZZ_TERMS/)
  } else if (privacyPolicyUrl) {
    translatedText = I18n.t('You agree to the %{privacyPolicyLink}.', {
      privacyPolicyLink: 'ZZZZ_PRIVACY',
    })
    splitText = translatedText.split(/ZZZZ_PRIVACY/)
  }

  return (
    <Checkbox
      id={id}
      label={
        <>
          {splitText[0]}
          {termsOfUseUrl && (
            <Link href={termsOfUseUrl} target="_blank">
              {I18n.t('terms of use')}
            </Link>
          )}
          {splitText[1]}
          {privacyPolicyUrl && (
            <Link href={privacyPolicyUrl} target="_blank">
              {I18n.t('privacy policy')}
            </Link>
          )}
          {splitText[2] && splitText[2]}
        </>
      }
      inline={true}
      disabled={isDisabled}
      isRequired={isRequired}
      aria-required={isRequired ? true : undefined}
      onChange={(e: React.ChangeEvent<HTMLInputElement>) => onChange(e.target.checked)}
      onFocus={onFocus}
      checked={checked}
      messages={messages}
      data-testid="terms-and-policy-checkbox"
    />
  )
}

export default TermsAndPolicyCheckbox
