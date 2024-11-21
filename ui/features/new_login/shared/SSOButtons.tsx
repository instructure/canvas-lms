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
import type {AuthProvider} from '../types'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Responsive} from '@instructure/ui-responsive'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {canvas} from '@instructure/ui-theme-tokens'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

import iconApple from '../assets/images/apple.svg'
import iconClasslink from '../assets/images/classlink.svg'
import iconClever from '../assets/images/clever.svg'
import iconFacebook from '../assets/images/facebook.svg'
import iconGithub from '../assets/images/github.svg'
import iconGoogle from '../assets/images/google.svg'
import iconLinkedin from '../assets/images/linkedin.svg'
import iconMicrosoft from '../assets/images/microsoft.svg'
import iconX from '../assets/images/x.svg'

const I18n = useI18nScope('new_login')

const providerIcons: Record<string, string> = {
  apple: iconApple,
  classlink: iconClasslink,
  clever: iconClever,
  facebook: iconFacebook,
  github: iconGithub,
  google: iconGoogle,
  linkedin: iconLinkedin,
  microsoft: iconMicrosoft,
  twitter: iconX,
}

const SSOButtons = () => {
  const {isUiActionPending, isPreviewMode, authProviders} = useNewLogin()

  if (!authProviders || authProviders.length === 0) {
    return null
  }

  const handleClick = (
    event: React.KeyboardEvent<ViewOwnProps> | React.MouseEvent<ViewOwnProps>
  ) => {
    if (isPreviewMode || isUiActionPending) {
      event.preventDefault()
    }
  }

  const renderProviderButton = (provider: AuthProvider) => {
    if (!provider.auth_type || !provider.display_name) return null

    const onlyOneOfType = authProviders.filter(p => p.auth_type === provider.auth_type).length < 2
    const authType = provider.auth_type
    const displayName = provider.display_name
    const link = `/login/${authType}${onlyOneOfType ? '' : `/${provider.id}`}`
    const iconSrc = providerIcons[authType]

    return (
      <Flex.Item
        key={provider.id}
        overflowX="visible"
        overflowY="visible"
        shouldGrow={true}
        size={`calc(50% - ${canvas.spacing.small})`}
      >
        <Button
          href={link}
          display="block"
          disabled={isUiActionPending}
          onClick={handleClick}
          width="100%"
        >
          {iconSrc && (
            <View
              position="absolute"
              insetInlineStart="0.625rem"
              insetBlockStart="50%"
              style={{
                transform: 'translateY(-50%)',
              }}
            >
              <Img display="block" height="1.125rem" src={iconSrc} width="1.125rem" />
            </View>
          )}
          {I18n.t('Log in with %{displayName}', {displayName})}
        </Button>
      </Flex.Item>
    )
  }

  return (
    <Responsive
      match="media"
      query={{
        desktop: {minWidth: canvas.breakpoints.desktop}, // 1024px
      }}
    >
      {(_props, matches) => {
        const isDesktopOrLarger = matches?.includes('desktop')

        return (
          <Flex
            direction={isDesktopOrLarger ? 'row' : 'column'}
            wrap={isDesktopOrLarger ? 'wrap' : 'no-wrap'}
            gap="small"
            justifyItems={isDesktopOrLarger ? 'start' : 'center'}
            alignItems="stretch"
          >
            {authProviders.map(renderProviderButton)}
          </Flex>
        )
      }}
    </Responsive>
  )
}

export default SSOButtons
