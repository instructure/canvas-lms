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

/**
 * Wrappers that can be mocked in tests, cf.
 *   https://github.com/jsdom/jsdom/issues/3492
 *   https://github.com/jestjs/jest/issues/5124
 */

export const openWindow = (
  url: string,
  target?: string,
  windowFeatures?: string,
): Window | null => {
  return window.open(url, target, windowFeatures)
}

export function replaceLocation(url: string): void {
  window.location.replace(url)
}

export function reloadWindow(): void {
  window.location.reload()
}

export function assignLocation(url: string): void {
  window.location.assign(url)
}

export function forceReload(): void {
  window.location.search = window.location.search + '&for_reload=1'
}

export function windowAlert(message: string): void {
  window.alert(message)
}

export function windowConfirm(message: string): boolean {
  return window.confirm(message)
}

export function windowPathname(): string {
  return window.location.pathname
}
