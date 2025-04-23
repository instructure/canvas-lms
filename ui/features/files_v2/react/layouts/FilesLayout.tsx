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

import React from "react"
import { HeaderLayout } from "./HeaderLayout"
import { FooterLayout } from "./FooterLayout"
import { TableControlsLayout } from "./TableControlsLayout"
import { Flex } from "@instructure/ui-flex"
import { View } from "@instructure/ui-view"

export const FilesLayout = (props: {
  size: 'small' | 'medium' | 'large',
  title: React.ReactNode,
  headerActions: React.ReactNode,
  search: React.ReactNode,
  breadcrumbs: React.ReactNode,
  bulkActions: React.ReactNode,
  progress: React.ReactNode,
  table: React.ReactNode,
  usageBar?: React.ReactNode,
  pagination?: React.ReactNode,
}) => {
  const header = <HeaderLayout
    size={props.size}
    title={props.title}
    actions={props.headerActions}
  />
  const tableControls = <TableControlsLayout
    breadcrumbs={props.breadcrumbs}
    bulkActions={props.bulkActions}
    size={props.size}
  />
  const footer = <FooterLayout
    usageBar={props.usageBar}
    pagination={props.pagination}
  />

  return (
    <Flex
      as='div'
      direction='column'
      margin='medium none none none'
    >
      <View as='div' margin='none none x-large'>
        {header}
      </View>
      <View as='div' margin='none none medium'>
        {props.search}
      </View>
      <View as='div' margin='none none medium'>
        {tableControls}
      </View>
      <View as='div'>
        {props.progress}
      </View>
      <View as='div' margin='none none medium'>
        {props.table}
      </View>
      <View as='div'>
        {footer}
      </View>
    </Flex>
  )
}
