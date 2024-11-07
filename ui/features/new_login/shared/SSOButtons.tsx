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
import type {AuthProvider} from '../types'
import type {ViewOwnProps} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {Grid, GridCol, GridRow} from '@instructure/ui-grid'
import {Img} from '@instructure/ui-img'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

// @ts-expect-error
import iconApple from '../assets/images/apple.svg'
// @ts-expect-error
import iconClasslink from '../assets/images/classlink.svg'
// @ts-expect-error
import iconClever from '../assets/images/clever.svg'
// @ts-expect-error
import iconFacebook from '../assets/images/facebook.svg'
// @ts-expect-error
import iconGithub from '../assets/images/github.svg'
// @ts-expect-error
import iconGoogle from '../assets/images/google.svg'
// @ts-expect-error
import iconLinkedin from '../assets/images/linkedin.svg'
// @ts-expect-error
import iconMicrosoft from '../assets/images/microsoft.svg'
// @ts-expect-error
import iconX from '../assets/images/x.svg'

const I18n = useI18nScope('new_login')

interface Props {
  className?: string
}

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

const SSOButtons = ({className}: Props) => {
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
      <GridCol key={provider.id} width={{small: 12, large: 6}}>
        <Button
          href={link}
          display="block"
          disabled={isUiActionPending}
          renderIcon={() => (
            <Img
              src={iconSrc}
              alt={displayName}
              width="1.125rem"
              height="1.125rem"
              display="block"
            />
          )}
          onClick={handleClick}
        >
          {I18n.t('Sign in with %{displayName}', {displayName})}
        </Button>
      </GridCol>
    )
  }

  return (
    <Grid startAt="x-large" colSpacing="small" rowSpacing="small" className={classNames(className)}>
      <GridRow hAlign="space-around">{authProviders.map(renderProviderButton)}</GridRow>
    </Grid>
  )
}

export default SSOButtons
