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
import {TruncateText} from '@instructure/ui-truncate-text'
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
        tablet: {minWidth: '48rem'},
        desktop: {minWidth: '75rem'},
      }}
    >
      {(_props, matches) => {
        const largerScreen = matches?.includes('desktop')
        return (
          <Flex
            as="div"
            direction="column"
            height={largerScreen ? '7.5rem' : '5rem'}
            gap="small"
            alignItems="center"
            justifyItems="center"
            className={classNames(className)}
          >
            <Flex.Item
              style={{maxWidth: largerScreen ? '18.75rem' : '11.25rem'}}
              shouldShrink={true}
            >
              <Img width="100%" height="100%" constrain="contain" src={src} alt={alt} />
            </Flex.Item>

            {alt && (
              <Flex.Item textAlign="center">
                <Text size="x-small">
                  <TruncateText>{alt}</TruncateText>
                </Text>
              </Flex.Item>
            )}
          </Flex>
        )
      }}
    </Responsive>
  )
}

export default LoginLogo
