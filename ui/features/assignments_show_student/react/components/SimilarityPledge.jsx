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

import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'
import {direction} from '@canvas/i18n/rtlHelper'

const I18n = useI18nScope('assignments_2_file_upload')

function eulaHTML(eulaUrl) {
  const encodedUrl = encodeURI(eulaUrl)

  // xsslint safeString.identifier encodedUrl
  return I18n.t("I agree to the tool's *End-User License Agreement*", {
    wrappers: [`<a target="_blank" href="${encodedUrl}">$1</a>`],
  })
}

export default function SimilarityPledge(props) {
  const {eulaUrl, pledgeText} = props
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

  return (
    <div style={{textAlign: direction('left')}} data-testid="similarity-pledge">
      {props.comments && (
        <Text
          as="p"
          dangerouslySetInnerHTML={{__html: props.comments}}
          data-testid="similarity-pledge-comments"
          size="small"
        />
      )}

      <Checkbox
        checked={props.checked}
        data-testid="similarity-pledge-checkbox"
        label={label}
        onChange={props.onChange}
      />
    </div>
  )
}

SimilarityPledge.propTypes = {
  eulaUrl: PropTypes.string,
  checked: PropTypes.bool.isRequired,
  comments: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  pledgeText: PropTypes.string,
}
