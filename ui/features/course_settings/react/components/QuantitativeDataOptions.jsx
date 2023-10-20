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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {bool} from 'prop-types'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('quantitative_data_options')

export default function QuantitativeDataOptions({canManage}) {
  const FORM_IDS = {
    RESTRICT_QUANTITATIVE_DATA: 'course_restrict_quantitative_data',
  }

  const setFormValue = (id, value) => {
    const field = document.getElementById(id)
    field.value = value
  }

  const getFormValue = id => document.getElementById(id).value

  const [viewQuantitativeData, setViewQuantitativeData] = useState(
    getFormValue(FORM_IDS.RESTRICT_QUANTITATIVE_DATA) === 'true'
  )

  return (
    <div className="QuantitativeDataOptions">
      <FormFieldGroup
        description={
          <ScreenReaderContent>{I18n.t('Quantitative Data Options')}</ScreenReaderContent>
        }
        rowSpacing="small"
        layout="inline"
      >
        <Checkbox
          label={I18n.t('Restrict view of quantitative data')}
          size="small"
          data-testid="restrict-quantitative-data-checkbox"
          disabled={!canManage}
          checked={viewQuantitativeData}
          onChange={e => {
            setFormValue(FORM_IDS.RESTRICT_QUANTITATIVE_DATA, e.target.checked)
            setViewQuantitativeData(e.target.checked)
          }}
        />
      </FormFieldGroup>
    </div>
  )
}

QuantitativeDataOptions.propTypes = {
  canManage: bool.isRequired,
}
