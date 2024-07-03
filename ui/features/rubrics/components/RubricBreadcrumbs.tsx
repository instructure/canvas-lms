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
import {Breadcrumb} from '@instructure/ui-breadcrumb'

type BreadcrumbsProps = {
  breadcrumbs: {name: string; url: string | null}[]
}

export const RubricBreadcrumbs = ({breadcrumbs}: BreadcrumbsProps) => {
  return (
    <Breadcrumb label="Breadcrumbs" themeOverride={{mediumFontSize: '1.125rem'}}>
      {breadcrumbs.map(({name, url}, index) => {
        const isLastIndex = index === breadcrumbs.length - 1
        const href = isLastIndex ? undefined : url
        return (
          <Breadcrumb.Link href={href ?? ''} key={href ?? -1}>
            {name}
          </Breadcrumb.Link>
        )
      })}
    </Breadcrumb>
  )
}
