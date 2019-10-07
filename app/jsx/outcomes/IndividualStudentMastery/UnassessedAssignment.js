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

import React from 'react'
import {object} from 'prop-types'
import I18n from 'i18n!IndividualStudentMasteryUnassessedAssignment'
import _ from 'lodash'
import {ApplyTheme} from '@instructure/ui-themeable'
import {View} from '@instructure/ui-layout'
import {Button} from '@instructure/ui-buttons'
import {IconAssignmentLine, IconQuizLine} from '@instructure/ui-icons'
import {List} from '@instructure/ui-elements'

const UnassessedAssignment = ({assignment}) => {
  const {id, url, submission_types, title} = assignment
  return (
    <List.Item key={id}>
      <View padding="small" display="block">
        <ApplyTheme theme={{[Button.theme]: {linkColor: '#68777D', fontWeight: '700'}}}>
          <Button
            href={url}
            variant="link"
            theme={{mediumPadding: '0', mediumHeight: 'normal'}}
            icon={_.includes(submission_types, 'online_quiz') ? IconQuizLine : IconAssignmentLine}
          >
            {title} ({I18n.t('Not yet assessed')})
          </Button>
        </ApplyTheme>
      </View>
    </List.Item>
  )
}

UnassessedAssignment.propTypes = {
  assignment: object.isRequired // eslint-disable-line react/forbid-prop-types
}

export default UnassessedAssignment
