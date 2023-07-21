/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

// OverrideAssignment is a placeholder for the real deal,
// which is a pretty complicated component.
// See https://instructure.invisionapp.com/share/24JU28K6TZJ#/screens/318751364
import React from 'react'
import {bool, oneOf} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {FormField} from '@instructure/ui-form-field'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {OverrideShape} from '../../assignmentData'

const I18n = useI18nScope('assignments_2')

OverrideAssignTo.propTypes = {
  override: OverrideShape.isRequired,
  variant: oneOf(['summary', 'detail']),
  readOnly: bool,
}
OverrideAssignTo.defaultProps = {
  variant: 'summary',
  readOnly: false,
}

// mostly lifted from instui Pill, but that component uppercases
// the text, which I don't want here, so rolling my own
const pillStyle = {
  display: 'inline-block',
  margin: '.25rem',
  padding: '0 .5rem',
  borderRadius: '.75rem',
  height: '1.5rem',
  border: '1px solid #c7cdd1',
  backgroundColor: '#eee',
}

export default function OverrideAssignTo(props) {
  const assignedTo =
    props.override.set.__typename === 'AdhocStudents'
      ? props.override.set.students
      : [props.override.set]
  return props.variant === 'summary' ? renderSummary(assignedTo) : renderDetail(assignedTo)
}

function renderSummary(assignedTo) {
  const list = assignedTo.length > 0 ? assignedTo.map(renderOverrideName).join(', ') : null
  return (
    <Text weight="bold" color="primary" data-testid="OverrideAssignTo" size="large">
      {list || <span dangerouslySetInnerHTML={{__html: '&nbsp;'}} />}
    </Text>
  )
}

// TODO: replace with the real deal with the popup and tabs etc. from the mockup
function renderDetail(assignedTo) {
  return (
    <View as="div" margin="small 0" data-testid="OverrideAssignTo">
      <FormField id="override_assign_to" label={I18n.t('Assign to:')} layout="stacked">
        <View as="div" borderWidth="small">
          {assignedTo.map(a => (
            <div key={a.lid} style={pillStyle}>
              {renderOverrideName(a)}
            </div>
          ))}
        </View>
      </FormField>
    </View>
  )
}

function renderOverrideName(assignedTo) {
  return (
    assignedTo.sectionName ||
    assignedTo.studentName ||
    (assignedTo.hasOwnProperty('groupName') && (assignedTo.groupName || 'unnamed group')) ||
    ''
  )
}
