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
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {useNewLogin} from '../context/NewLoginContext'

interface Props {
  className?: string
}

const LoginLogo = ({className}: Props) => {
  const {loginLogoUrl: src, loginLogoAlt: alt} = useNewLogin()

  if (!src) return null

  return (
    <Responsive
      match="media"
      query={{
        tablet: {minWidth: '48rem'}, // 768px
        desktop: {minWidth: '75rem'}, // 1200px
      }}
    >
      {(_props, matches) => {
        const isDesktop = matches?.includes('desktop')
        const isTablet = matches?.includes('tablet')
        const width = isDesktop ? '18.75rem' : isTablet ? '23.25rem' : '11.25rem' // 300px, 372px, 180px
        const height = isDesktop ? '7.5rem' : '5rem' // 120px, 80px

        return (
          <Flex
            direction="column"
            height={height}
            gap="x-small"
            alignItems="center"
            justifyItems="center"
            className={classNames(className)}
          >
            <Flex.Item width={width} shouldShrink={true}>
              <Img width="100%" height="100%" constrain="contain" src={src} alt={alt} />
            </Flex.Item>

            {alt && (
              <Flex.Item textAlign="center">
                <Text size="x-small">{alt}</Text>
              </Flex.Item>
            )}
          </Flex>
        )
      }}
    </Responsive>
  )
}

export default LoginLogo
