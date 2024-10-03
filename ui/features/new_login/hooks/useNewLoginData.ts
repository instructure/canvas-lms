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

import {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {AuthProvider} from '../types'

const I18n = useI18nScope('new_login')

interface NewLoginData {
  authProviders: AuthProvider[]
  loginHandleName: string
}

const getLoginDataContainer = (): HTMLElement | null => {
  return document.getElementById('new_login_data')
}

const getAuthProviders = (container: HTMLElement): AuthProvider[] => {
  const data = container.getAttribute('data-auth-providers')
  return data ? (JSON.parse(data) as AuthProvider[]) : []
}

const getLoginHandleName = (container: HTMLElement): string => {
  return container.getAttribute('data-login-handle-name') || I18n.t('Email')
}

export const useNewLoginData = (): NewLoginData => {
  const [newLoginData, setNewLoginData] = useState<NewLoginData>({
    authProviders: [],
    loginHandleName: '',
  })

  useEffect(() => {
    const container = getLoginDataContainer()

    if (container) {
      const authProviders = getAuthProviders(container)
      const loginHandleName = getLoginHandleName(container)

      setNewLoginData({
        authProviders,
        loginHandleName,
      })
    }
  }, [])

  return newLoginData
}
