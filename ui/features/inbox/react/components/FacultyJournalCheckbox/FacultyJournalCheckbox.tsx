/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../../util/utils'

const I18n = useI18nScope('conversations_2')

type Props = {
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void
  checked?: boolean
}

export const FacultyJournalCheckBox = (props: Props) => {
  return (
    <Responsive
      match="media"
      // @ts-expect-error
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          variant: 'toggle',
          dataTestId: 'faculty-message-checkbox-mobile',
        },
        desktop: {
          variant: 'simple',
          dataTestId: 'faculty-message-checkbox',
        },
      }}
      render={responsiveProps => (
        <Checkbox
          // @ts-expect-error
          data-testid={responsiveProps.dataTestId}
          label={I18n.t('Add as a Faculty Journal entry')}
          size="small"
          // @ts-expect-error
          variant={responsiveProps.variant}
          {...props}
        />
      )}
    />
  )
}

FacultyJournalCheckBox.defaultProps = {
  checked: false,
}
