/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useState} from 'react'
import FindUserToMerge from './FindUserToMerge'
import PreviewUserMerge from './PreviewUserMerge'
import {AccountSelectOption} from './common'
import {useNavigate, useParams} from 'react-router-dom'

enum Stage {
  FindUser,
  PreviewMerge,
}

export interface MergeUsersProps {
  accountSelectOptions: Array<AccountSelectOption>
  currentUserId: string
}

const MergeUsers = ({accountSelectOptions, currentUserId}: MergeUsersProps) => {
  const {userId: sourceUserId} = useParams()
  const navigate = useNavigate()
  const [stage, setStage] = useState(Stage.FindUser)
  const [destinationUserId, setDestinationUserId] = useState<string>()

  return (
    <>
      {stage === Stage.FindUser && (
        <FindUserToMerge
          sourceUserId={sourceUserId!}
          accountSelectOptions={accountSelectOptions}
          onFind={currentDestinationUserId => {
            setDestinationUserId(currentDestinationUserId)
            setStage(Stage.PreviewMerge)
          }}
        />
      )}
      {stage === Stage.PreviewMerge && destinationUserId && (
        <PreviewUserMerge
          currentUserId={currentUserId}
          sourceUserId={sourceUserId!}
          destinationUserId={destinationUserId}
          onSwap={() => {
            setDestinationUserId(sourceUserId!)
            navigate(`/users/${destinationUserId}/admin_merge`)
          }}
          onStartOver={newSourceUserId => {
            setDestinationUserId(undefined)
            navigate(`/users/${newSourceUserId}/admin_merge`)
            setStage(Stage.FindUser)
          }}
        />
      )}
    </>
  )
}

export default MergeUsers
