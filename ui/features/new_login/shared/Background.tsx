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

import React, {useMemo} from 'react'
import classNames from 'classnames'
import {useNewLogin} from '../context/NewLoginContext'

interface Props {
  className?: string
}

const Background = ({className}: Props) => {
  const {bodyBgColor, bodyBgImage} = useNewLogin()

  const backgroundStyle = useMemo(
    () => ({
      backgroundColor: bodyBgColor || undefined,
      backgroundImage: bodyBgImage ? `url(${bodyBgImage})` : undefined,
      backgroundPosition: 'left center',
      backgroundRepeat: 'no-repeat',
      backgroundSize: 'cover',
    }),
    [bodyBgColor, bodyBgImage]
  )

  return <div className={classNames(className)} style={backgroundStyle} />
}

export default Background
