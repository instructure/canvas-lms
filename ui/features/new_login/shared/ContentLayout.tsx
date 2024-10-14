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

import Background from './Background'
import React from 'react'
import classNames from 'classnames'
import {View} from '@instructure/ui-view'

// @ts-expect-error
import styles from './ContentLayout.module.css'

interface Props {
  className?: string
  children: React.ReactNode
}

const ContentLayout = ({className, children}: Props) => (
  <View as="div" height="100%" position="relative" className={styles.contentLayout}>
    <View
      as="div"
      className={classNames(className, styles.contentLayout__wrapper)}
      background="primary"
      position="relative"
    >
      {children}
    </View>

    <Background className={styles.contentLayout__background} />
  </View>
)

export default ContentLayout
