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
import classNames from 'classnames'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useNewLogin} from '../context/NewLoginContext'

// @ts-expect-error
import styles from './LoginLogo.module.css'

interface Props {
  className?: string
}

const LoginLogo = ({className}: Props) => {
  const {loginLogoUrl: src, loginLogoAlt: alt} = useNewLogin()

  if (!src) return null

  return (
    <View as="div" className={classNames(className, styles.loginLogo)}>
      <Img src={src} alt={alt} />
      {alt && (
        <Text size="x-small" className={styles.loginLogo__desc}>
          {alt}
        </Text>
      )}
    </View>
  )
}

export default LoginLogo
