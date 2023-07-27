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

import React, {useCallback} from 'react'
import PropTypes from 'prop-types'

import {useMutation} from 'react-apollo'
import {CREATE_GROUP_CATEGORY} from '../../../graphql/Mutations'

import LoadingIndicator from '@canvas/loading-indicator'
import CreateGroupCategoryModal from '../../components/CreateGroupCategoryModal/CreateGroupCategoryModal'

export default function CreateGroupCategoryModalContainer({show, setShow, afterCreate}) {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [createGroupCategory, {data, loading}] = useMutation(CREATE_GROUP_CATEGORY, {
    onCompleted: completionData => {
      const new_group_category = completionData?.createGroupCategory?.groupCategory
      const group_category_id = new_group_category?.id
      if (group_category_id) {
        afterCreate(new_group_category.name)
        setShow(false)
      } else {
        // TODO: handle this
        // eslint-disable-next-line no-console
        console.log('invalid group category!')
      }
    },
    onError: () => {
      // TODO: handle mutation error and potentially try again
      // eslint-disable-next-line no-console
      console.log('mutation error!')
    },
  })

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const onSubmit = useCallback(
    ({
      groupName,
      groupStructure,
      allowSelfSignUp,
      requireSameSection,
      autoAssignGroupLeader,
      numberOfGroups,
      studentsPerGroup,
      groupLeaderAssignmentMethod,
    }) =>
      createGroupCategory({
        variables: {
          contextId: ENV.course_id, // TODO: add context_id to js_env
          contextType: 'Course',
          groupName,
          groupStructure,
          allowSelfSignUp,
          requireSameSection,
          autoAssignGroupLeader,
          numberOfGroups,
          studentsPerGroup,
          groupLeaderAssignmentMethod,
        },
      }),
    [createGroupCategory]
  )

  if (loading) {
    // TODO: this the place for the "creating a group, you can close this" window
    return <LoadingIndicator />
  }

  return (
    <CreateGroupCategoryModal show={show} setShow={setShow} onSubmit={() => {} /* onSubmit */} />
  )
}

CreateGroupCategoryModalContainer.propTypes = {
  show: PropTypes.bool,
  setShow: PropTypes.func,
  afterCreate: PropTypes.func,
}

CreateGroupCategoryModalContainer.defaultProps = {
  show: false,
  setShow: () => {},
  afterCreate: () => {},
}
