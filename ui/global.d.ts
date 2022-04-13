/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

declare global {
  interface Global {
    readonly ENV?: any
  }

  interface Window {
    readonly ENV?: any
    external_tool_redirect: any
    webkitSpeechRecognition: any
    jsonData: any
  }

  const ENV: any

  declare interface JQuery {
    confirmDelete: any
    fillWindowWithMe: (options?: {onResize: () => void}) => void
    fixDialogButtons: () => void
    live: any
    mediaComment: any
    showIf: (boolean) => void
  }

  declare interface JQueryStatic {
    flashError: (any, number?) => void
    subscribe: any
    ajaxJSON: (
      url: string,
      submit_type?: string,
      data?: any,
      success?: any,
      error?: any,
      options?: any
    ) => JQuery.JQueryXHR
    flashWarning: any
    flashMessage: any
    replaceTags: (string, string, string?) => string
    raw: any
    getScrollbarWidth: any
    datetimeString: any
    ajaxJSONFiles: any
    isPreviewable: any
    toSentence: any
  }

  declare interface Array<T> {
    flatMap: <Y>(callback: (value: T, index: number, array: T[]) => Y[]) => Y[]
    flat: <Y>(depth?: number) => Y[]
  }

  declare interface Object {
    fromEntries: any
  }
}

// Global scope declarations are only allowed in module contexts, so we
// need this to make Typescript think this is a module.
export {}
