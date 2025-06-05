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

import {useEffect} from 'react'
import {BaseBlock, useIsEditMode} from './BaseBlock'
import {useSave} from './BaseBlock/useSave'

export const DummyBlock = (props: {
  dummyValue: string
}) => {
  return (
    <BaseBlock title="Dummy Block">
      <DummyBlockContent dummyValue={props.dummyValue} />
    </BaseBlock>
  )
}

const DummyBlockContent = (props: {dummyValue: string}) => {
  const isEditMode = useIsEditMode()
  const save = useSave<typeof DummyBlock>()

  useEffect(() => {
    if (!isEditMode) {
      save({
        dummyValue: Math.random().toString(),
      })
    }
  }, [isEditMode])

  return isEditMode
    ? 'EDIT MODE: This is a dummy block. It serves as a placeholder for testing purposes.'
    : `This is a dummy block. It serves as a placeholder for testing purposes. ${props.dummyValue}`
}
