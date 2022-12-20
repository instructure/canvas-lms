/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export const STORAGE_KEY: string = 'NEE_should_reopen_advanced'

type StorageInteractionSuccess<T> = {
  state: 'success'
  returnValue: T
}

type StorageInteractionFailure = {
  state: 'failure'
}

type StorageInteractionState<T> = StorageInteractionSuccess<T> | StorageInteractionFailure

function wrapInErrorHandling<T>(func: () => T): StorageInteractionState<T> {
  try {
    return {state: 'success', returnValue: func()}
  } catch (exception) {
    // eslint-disable-next-line no-console
    console.warn('Store interaction failed: ', exception)
    return {state: 'failure'}
  }
}

export const isSet = (): boolean => {
  const result = wrapInErrorHandling<boolean>(() => {
    const value = window.sessionStorage.getItem(STORAGE_KEY) || 'null'
    return !!JSON.parse(value)
  })

  return result.state === 'success' ? result.returnValue : false
}

export const set = (): void => {
  wrapInErrorHandling<void>(() => {
    window.sessionStorage.setItem(STORAGE_KEY, 'true')
  })
}

export const remove = (): void => {
  wrapInErrorHandling<void>(() => {
    window.sessionStorage.removeItem(STORAGE_KEY)
  })
}
