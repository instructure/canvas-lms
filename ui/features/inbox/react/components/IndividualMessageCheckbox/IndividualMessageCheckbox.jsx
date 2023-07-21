/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'

const I18n = useI18nScope('conversations_2')

export const IndividualMessageCheckbox = ({checked, maxGroupRecipientsMet, ...props}) => {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          variant: 'toggle',
          dataTestId: 'individual-message-checkbox-mobile',
        },
        desktop: {
          variant: 'simple',
          dataTestId: 'individual-message-checkbox',
        },
      }}
      render={responsiveProps => (
        <Checkbox
          data-testid={responsiveProps.dataTestId}
          label={I18n.t('Send an individual message to each recipient')}
          size="small"
          variant={responsiveProps.variant}
          {...props}
          checked={checked || maxGroupRecipientsMet}
          disabled={maxGroupRecipientsMet}
        />
      )}
    />
  )
}

IndividualMessageCheckbox.propTypes = {
  onChange: PropTypes.func.isRequired,
  checked: PropTypes.bool,
  maxGroupRecipientsMet: PropTypes.bool,
}

IndividualMessageCheckbox.defaultProps = {
  checked: false,
}
