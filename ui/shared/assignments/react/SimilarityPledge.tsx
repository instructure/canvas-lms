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

import React, {LegacyRef, useState, useEffect} from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormMessage} from '@instructure/ui-form-field/types/FormPropTypes'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignments_similarity_pledge')

function eulaHTML(eulaUrl: string) {
  const encodedUrl = encodeURI(eulaUrl)

  // xsslint safeString.identifier encodedUrl
  return I18n.t("I agree to the tool's *End-User License Agreement*", {
    wrappers: [`<a target="_blank" href="${encodedUrl}">$1</a>`],
  })
}

type SimilarityPledgeProps = {
  inputId?: string,
  pledgeText: string
  setShouldShowPledgeError: (showShow: boolean, type?: string) => {},
  checked?: boolean,
  eulaUrl?: string,
  comments?: string,
  shouldShowPledgeError?: boolean,
  onChange?: () => void,
  getShouldShowPledgeError?: (type?: string) => boolean | void,
  getIsChecked?: () => boolean | void,
  checkboxRef?: LegacyRef<Checkbox>,
  type?: string
}

const SimilarityPledge = ({
  inputId = 'turnitin_pledge',
  setShouldShowPledgeError,
  eulaUrl = '',
  comments = '',
  pledgeText = '',
  onChange = () => {},
  getShouldShowPledgeError = () => {},
  checked = false,
  shouldShowPledgeError = undefined,
  checkboxRef = null,
  type = ''
}: SimilarityPledgeProps) => {

  const [errorMessages, setErrorMessages] = useState<FormMessage[]>([])
  const [isChecked, setIsChecked] = useState<boolean>(checked)

  const label = eulaUrl ? (
    <span>
      <Text dangerouslySetInnerHTML={{__html: eulaHTML(eulaUrl)}} />
      {!!pledgeText && (
        <div>
          <Text>{pledgeText}</Text>
        </div>
      )}
    </span>
  ) : (
    <Text>{pledgeText}</Text>
  )

  useEffect(() => {
    if (shouldShowPledgeError) {
      setErrorMessages([{type: 'newError', text: I18n.t('You must agree to the submission pledge before you can submit the assignment')}])
    }
  }, [shouldShowPledgeError])

  useEffect(() => {
    // We remove the required attribute here so we do not get native validations
    document.querySelector(`#turnitin_pledge_container${type ? '_' + type : ''} input[name="turnitin_pledge"]`)?.removeAttribute('required')
  }, [type])

  const handleOnChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setIsChecked(e.target.checked)
    if (e.target.checked) {
      setErrorMessages([])
      // reset the value
      setShouldShowPledgeError(false, type)
    }
    onChange()
  }

  const handleFocus = (_e: React.FocusEvent<HTMLInputElement>) => {
    if (getShouldShowPledgeError(type) && !isChecked) {
      setErrorMessages([{type: 'newError', text: I18n.t('You must agree to the submission pledge before you can submit the assignment')}])
      // reset the value
      setShouldShowPledgeError(false, type)
    }
  }

  return (
    <View as="div" textAlign="start" data-testid="similarity-pledge">
      {comments && (
        <Text
          as="p"
          dangerouslySetInnerHTML={{__html: comments}}
          data-testid="similarity-pledge-comments"
          size="small"
        />
      )}

      <Checkbox
        id={type ? `${inputId}_${type}` : inputId}
        ref={checkboxRef}
        checked={isChecked}
        data-testid="similarity-pledge-checkbox"
        label={label}
        onChange={handleOnChange}
        onFocus={handleFocus}
        messages={errorMessages}
        isRequired={true}
        name='turnitin_pledge'
      />
    </View>
  )
}

export default SimilarityPledge
