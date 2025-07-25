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

import {ComponentProps, PropsWithChildren, useState} from 'react'
import {BlockContext} from './BaseBlockContext'
import {useGetRenderMode} from './useGetRenderMode'
import {BaseBlockViewLayout} from './layout/BaseBlockViewLayout'
import {BaseBlockEditWrapper} from './components/BaseBlockEditWrapper'

const BaseBlockContent = (
  props: ComponentProps<typeof BaseBlock> & {
    setIsEditMode: (isEditMode: boolean) => void
  },
) => {
  const renderMode = useGetRenderMode()
  return renderMode === 'view' ? (
    <BaseBlockViewLayout>{props.children}</BaseBlockViewLayout>
  ) : (
    <BaseBlockEditWrapper {...props} isEditMode={renderMode === 'edit'} />
  )
}

export const BaseBlock = (
  props: PropsWithChildren<{
    title: string
  }>,
) => {
  const [isEditMode, setIsEditMode] = useState(false)
  return (
    <BlockContext.Provider value={{isEditMode}}>
      <BaseBlockContent {...props} setIsEditMode={setIsEditMode} />
    </BlockContext.Provider>
  )
}
