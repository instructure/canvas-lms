/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {Fragment} from 'react'
import {bool, func, oneOf} from 'prop-types'

import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'

import I18n from 'i18n!hide_assignment_grades_tray'

export const EVERYONE = 'everyone'
export const GRADED = 'graded'

export default function PostTypes(props) {
  return (
    <RadioInputGroup
      defaultValue={props.defaultValue}
      description={
        <ScreenReaderContent>
          {I18n.t('Select whether to post for all submissions, or only graded ones.')}
        </ScreenReaderContent>
      }
      disabled={props.disabled}
      onChange={props.postTypeChanged}
      name={I18n.t('Post types')}
    >
      <RadioInput
        label={
          <Fragment>
            <Text>{I18n.t('Everyone')}</Text>
            <br />
            <Text size="small">{I18n.t('Grades will be made visible to all students')}</Text>
          </Fragment>
        }
        value={EVERYONE}
      />
      <RadioInput
        label={
          <Fragment>
            <Text>{I18n.t('Graded')}</Text>
            <br />
            <Text size="small">
              {I18n.t('Grades will be made visible to students with graded submissions')}
            </Text>
          </Fragment>
        }
        value={GRADED}
      />
    </RadioInputGroup>
  )
}

PostTypes.propTypes = {
  defaultValue: oneOf([EVERYONE, GRADED]).isRequired,
  disabled: bool.isRequired,
  postTypeChanged: func.isRequired
}
