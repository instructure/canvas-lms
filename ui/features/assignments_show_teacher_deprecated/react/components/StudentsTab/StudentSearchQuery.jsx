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

import React from 'react'
import {func} from 'prop-types'
import {Query} from 'react-apollo'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {STUDENT_SEARCH_QUERY, StudentSearchQueryShape} from '../../assignmentData'

const I18n = useI18nScope('assignments_2')

StudentSearchQuery.propTypes = {
  children: func,
  variables: StudentSearchQueryShape,
}

export default function StudentSearchQuery({variables, children}) {
  return (
    <Query query={STUDENT_SEARCH_QUERY} variables={variables}>
      {({loading, error, data}) => {
        if (loading) {
          return (
            <View as="div" textAlign="center" padding="large 0">
              <Spinner size="large" renderTitle={I18n.t('Loading')} />
            </View>
          )
        } else if (error) {
          // TODO: divert to error boundary?
          return <pre>Error: {JSON.stringify(error, null, 2)}</pre>
        }
        return children(data.assignment.submissions.nodes)
      }}
    </Query>
  )
}
