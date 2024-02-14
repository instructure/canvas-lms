/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {PageBreadcrumb} from '../types'

type AdminHeaderProps = {
  title: string | React.ReactNode
  description?: string
  breadcrumbs?: PageBreadcrumb[]
  children?: React.ReactChild // for any buttons in the header
}
const AdminHeader = ({title, description, breadcrumbs, children}: AdminHeaderProps) => {
  const renderBreadcrumbs = () => {
    if (!breadcrumbs || breadcrumbs.length === 0) {
      return null
    }

    return (
      <Breadcrumb label="You are here:" size="small">
        {breadcrumbs.map((crumb: PageBreadcrumb) => {
          return (
            <Breadcrumb.Link key={crumb.text} href={crumb.url}>
              {crumb.text}
            </Breadcrumb.Link>
          )
        })}
      </Breadcrumb>
    )
  }

  return (
    <View as="div" margin="medium large large large">
      {renderBreadcrumbs()}
      <Flex as="div" alignItems="start" margin="large 0 0 0">
        <Flex.Item shouldGrow={true}>
          {typeof title === 'string' ? <Heading level="h1">{title}</Heading> : title}
          {description && (
            <Text as="div" size="large">
              {description}
            </Text>
          )}
        </Flex.Item>
        {children && <Flex.Item>{children}</Flex.Item>}
      </Flex>
    </View>
  )
}

export default AdminHeader
