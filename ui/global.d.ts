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

import {sendMessageStudentsWho} from './shared/grading/messageStudentsWhoHelper'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {GlobalInst} from '@canvas/global/inst/GlobalInst'
import {GlobalRemotes} from '@canvas/global/remotes/GlobalRemotes'

declare global {
  interface Global {
    /**
     * Global environment variables provided by the server.
     */
    readonly ENV?: GlobalEnv

    /**
     * Utility global for various values and utility functions, some provided by the server,
     * some by client code.
     */
    readonly INST?: GlobalInst

    /**
     * Remote locations for various pure front-end functionality.
     */
    readonly REMOTES?: GlobalRemotes
  }

  interface Window {
    /**
     * Global environment variables provided by the server.
     *
     * Note: should be readonly, but some tests overwrite.
     */
    ENV: GlobalEnv

    /**
     * Utility global for various values and utility functions, some provided by the server,
     * some by client code.
     *
     * Should be readonly, but tests overwrite
     */
    INST: GlobalInst

    webkitSpeechRecognition: any
    messageStudents: (options: ReturnType<typeof sendMessageStudentsWho>) => void
    updateGrades: () => void

    bundles: string[]
    deferredBundles: string[]
    canvasReadyState?: 'loading' | 'complete'
  }

  /**
   * Global environment variables provided by the server.
   */
  const ENV: GlobalEnv

  /**
   * Utility global for various values and utility functions, some provided by the server,
   * some by client code.
   */
  const INST: GlobalInst

  /**
   * Remote locations for various pure front-end functionality.
   */
  const REMOTES: GlobalRemotes

  type ShowIf = {
    (bool?: boolean): JQuery<HTMLElement>
    /**
     * @deprecated use a boolean parameter instead
     * @param num
     * @returns
     */
    (num?: number): JQuery<HTMLElement>
  }

  declare interface JQuery {
    scrollTo: (y: number, x?: number) => void
    change: any
    confirmDelete: any
    datetime_field: () => JQuery<HTMLInputElement>
    disableWhileLoading: any
    fileSize: (size: number) => string
    fillTemplateData: any
    fillWindowWithMe: (options?: {onResize: () => void}) => JQuery<HTMLElement>
    fixDialogButtons: () => void
    errorBox: (
      message: string,
      scroll?: boolean,
      override_position?: string | number
    ) => JQuery<HTMLElement>
    getFormData: <T>(obj?: Record<string, unknown>) => T
    live: any
    loadDocPreview: (options: {
      attachment_id: string
      attachment_preview_processing: boolean
      attachment_view_inline_ping_url: string | null
      height: string
      id: string
      mimeType: string
      submission_id: string
      crocodoc_session_url?: string
    }) => void
    mediaComment: any
    mediaCommentThumbnail: (size?: 'normal' | 'small') => void
    raw: (str: string) => string
    showIf: ShowIf
    underscore: (str: string) => string
    formSubmit: (options: {
      object_name?: string
      formErrors?: boolean
      disableWhileLoading?: boolean
      required: string[]
      success: (data: any) => void
      beforeSubmit?: (data: any) => void
      error: (response: JQuery.JQueryXHR) => void
    }) => void
    formErrors: (errors: Record<string, string>) => void
    getTemplateData: (options: {textValues: string[]}) => Record<string, unknown>
    fancyPlaceholder: () => void
    loadingImage: (str?: string) => void
  }

  declare interface JQueryStatic {
    subscribe: (topic: string, callback: (...args: any[]) => void) => void
    ajaxJSON: (
      url: string,
      submit_type?: string,
      data?: any,
      success?: any,
      error?: any,
      options?: any
    ) => JQuery.JQueryXHR
    replaceTags: (string, string, string?) => string
    raw: (str: string) => string
    getScrollbarWidth: any
    datetimeString: any
    ajaxJSONFiles: any
    isPreviewable: any
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
