/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {Editor, Frame} from '@craftjs/core'
import {Container} from '../../Container'
import {GroupBlock, type GroupBlockProps} from '..'
import {NoSections} from '../../../common'

const renderBlock = (props: Partial<GroupBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{GroupBlock, NoSections, Container}}>
      <Frame>
        <GroupBlock {...props} />
      </Frame>
    </Editor>
  )
}

describe('ColumnsSection', () => {
  it('should render ', () => {
    const {container} = renderBlock()
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveClass('column-layout')
  })

  it('should render with row direction', () => {
    const {container} = renderBlock({layout: 'row'})
    expect(container.querySelector('.group-block')).toBeInTheDocument()
    expect(container.querySelector('.group-block')).toHaveClass('row-layout')
  })
})
