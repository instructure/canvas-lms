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

import classNames from 'classnames'
import React, {useMemo} from 'react'
import {useNewLoginData} from '../context'

interface Props {
  className?: string
}

const Background = ({className}: Props) => {
  const {bodyBgColor, bodyBgImage} = useNewLoginData()

  const backgroundStyle = useMemo(
    () => ({
      backgroundColor: bodyBgColor || undefined,
      backgroundImage: bodyBgImage ? `url(${bodyBgImage})` : undefined,
      backgroundAttachment: 'fixed',
      backgroundRepeat: 'no-repeat',
      backgroundSize: 'cover',
    }),
    [bodyBgColor, bodyBgImage],
  )

  return <div className={classNames(className)} style={backgroundStyle} />
}

export default Background
