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

import {AlertManagerContext} from 'jsx/shared/components/AlertManager'
import {COURSES_QUERY} from '../Queries'
import {CourseSelect} from '../components/CourseSelect/CourseSelect'
import {Flex} from '@instructure/ui-flex'
import I18n from 'i18n!conversations_2'
import {MailboxSelectionDropdown} from '../components/MailboxSelectionDropdown/MailboxSelectionDropdown'
import {MessageActionButtons} from '../components/MessageActionButtons/MessageActionButtons'
import PropTypes from 'prop-types'
import {useQuery} from 'react-apollo'
import React, {useContext} from 'react'
import {View} from '@instructure/ui-view'

const MessageListActionContainer = props => {
  const {setOnFailure} = useContext(AlertManagerContext)
  const userID = ENV.current_user_id?.toString()

  const {loading, error, data} = useQuery(COURSES_QUERY, {
    variables: {userID}
  })

  const reduceDuplicateCourses = (enrollments, favoriteCourses) => {
    if (!enrollments || !favoriteCourses) {
      return []
    }
    return enrollments
      .map(c => {
        return {
          id: c.course.id,
          contextName: c.course.contextName,
          assetString: c.course.assetString
        }
      })
      .filter(c => {
        let isMatch
        for (let i = 0; i < favoriteCourses.length; i++) {
          isMatch = favoriteCourses[i].assetString === c.assetString
          if (isMatch === true) {
            break
          }
        }
        return !isMatch
      })
  }

  if (loading) {
    return <span />
  }

  if (error) {
    setOnFailure(I18n.t('Unable to load courses menu.'))
  }

  const moreCourses = reduceDuplicateCourses(
    data?.legacyNode?.enrollments,
    data?.legacyNode?.favoriteCoursesConnection?.nodes
  )

  return (
    <View
      as="div"
      display="inline-block"
      width="100%"
      margin="none"
      padding="small"
      background="secondary"
    >
      <Flex wrap="wrap">
        <Flex.Item>
          <CourseSelect
            mainPage
            options={{
              favoriteCourses: data?.legacyNode?.favoriteCoursesConnection?.nodes,
              moreCourses,
              concludedCourses: [],
              groups: data?.legacyNode?.favoriteGroupsConnection?.nodes
            }}
            onCourseFilterSelect={props.onCourseFilterSelect}
          />
        </Flex.Item>
        <Flex.Item padding="none none none xxx-small">
          <MailboxSelectionDropdown
            activeMailbox={props.activeMailbox}
            onSelect={props.onSelectMailbox}
          />
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink />
        <Flex.Item>
          <MessageActionButtons
            archive={() => {}}
            compose={props.onCompose}
            delete={() => {}}
            forward={() => {}}
            markAsUnread={() => {}}
            reply={() => {}}
            replyAll={() => {}}
            star={() => {}}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default MessageListActionContainer

MessageListActionContainer.propTypes = {
  activeMailbox: PropTypes.string,
  onCourseFilterSelect: PropTypes.func,
  onSelectMailbox: PropTypes.func,
  onCompose: PropTypes.func
}
