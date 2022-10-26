/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

const I18n = useI18nScope('external_tools')

export type AppTileProps = {
  app: App
  baseUrl: string
}

type App = {
  is_installed: boolean
  id: number
  short_name: string
  name: string
  banner_image_url: string
  short_description: string
}

export default function AppTile({baseUrl, app}: AppTileProps) {
  const installedRibbon = () => {
    if (app.is_installed) {
      return <div className="installed-ribbon">{I18n.t('Installed')}</div>
    }
  }
  const appId = `app_${app.id}`

  return (
    <a
      tabIndex={0}
      href={`${baseUrl}/app/${app.short_name}`}
      aria-label={I18n.t('View %{name} app', {name: app.name})}
      aria-describedby={`${appId}-desc`}
      className="app"
    >
      <div id={appId}>
        {installedRibbon()}

        <img className="banner_image" alt={app.name} src={app.banner_image_url} />
        <div className="details">
          <div className="content">
            <span className="name">{app.name}</span>
            <div id={`${appId}-desc`} className="desc">
              {app.short_description}
            </div>
          </div>
        </div>
      </div>
    </a>
  )
}
