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

import {ToggleGroup} from '@instructure/ui-toggle-details'
import {ContentError} from '../types'
import {List} from '@instructure/ui-list'
import {Link} from '@instructure/ui-link'

type ListItemProps = {
  label: string
  screenReaderLabel: string
  contents: ContentError[]
}
export const ContentItems = (props: ListItemProps) => {
  return (
    <ToggleGroup toggleLabel={props.screenReaderLabel} summary={props.label} as="div">
      <List isUnstyled itemSpacing="x-small">
        {props.contents.map((item, index) => (
          <List.Item key={index}>
            <Link href={item.link}>{item.name}</Link>
          </List.Item>
        ))}
      </List>
    </ToggleGroup>
  )
}
