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

import MessageStudentsWhoHelper from './shared/grading/messageStudentsWhoHelper'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {GlobalInst} from '@canvas/global/inst/GlobalInst'
import {GlobalRemotes} from '@canvas/global/remotes/GlobalRemotes'
import {ajaxJSON} from '@canvas/jquery/jquery.ajaxJSON'

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

    /**
     * Remote locations for various pure front-end functionality.
     */
    REMOTES: GlobalRemotes

    webkitSpeechRecognition: any
    messageStudents: (
      options: ReturnType<typeof MessageStudentsWhoHelper.sendMessageStudentsWho>,
    ) => void
    updateGrades: () => void

    bundles: string[]
    deferredBundles: string[]
    canvasReadyState?: 'loading' | 'complete'
    CANVAS_ACTIVE_BRAND_VARIABLES?: Record<string, unknown>
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

  interface JQuery<TResponse = any> {
    responseJSON?: TResponse & CanvasApiErrorResponse
    scrollTo: (y: number, x?: number) => void
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
      override_position?: string | number,
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
      error?: (data: JQuery.jqXHR) => void
      onClientSideValidationError?: () => void
      disableErrorBox?: boolean
    }) => void
    formErrors: (errors: Record<string, string>) => void
    getTemplateData: (options: {textValues: string[]}) => Record<string, unknown>
    fancyPlaceholder: () => void
    loadingImage: (str?: string) => void
  }

  interface CanvasApiErrorResponse {
    errors: {
      [key: string]: Array<{
        message: string
        type?: string
      }>
    }
  }

  interface JQueryStatic {
    subscribe: (topic: string, callback: (...args: any[]) => void) => void
    replaceTags: (text: string, name: string, value?: string) => string
    raw: (str: string) => string
    getScrollbarWidth: any
    datetimeString: any
    ajaxJSONFiles: any
    isPreviewable: any
    ajaxJSON: typeof ajaxJSON
  }

  // due to overrides in packages/date-js/core.js
  interface Date {
    add(config: {[key: string]: number}): Date
    addDays(value: number): Date
    addHours(value: number): Date
    addMilliseconds(value: number): Date
    addMinutes(value: number): Date
    addMonths(value: number): Date
    addSeconds(value: number): Date
    addWeeks(value: number): Date
    addYears(value: number): Date
    between(start: Date, end: Date): boolean
    clearTime(): Date
    clone(): Date
    compareTo(date: Date): number
    equals(date: Date): boolean
    getElapsed(date?: Date): number
    getOrdinalNumber(): number
    getTimezone(): string | null
    getUTCOffset(): string
    hasDaylightSavingTime(): boolean
    isAfter(date?: Date): boolean
    isBefore(date?: Date): boolean
    isDaylightSavingTime(): boolean
    isSameDay(date?: Date): boolean
    isToday(date?: Date): boolean
    moveToDayOfWeek(dayOfWeek: number, orient?: number): Date
    moveToFirstDayOfMonth(): Date
    moveToLastDayOfMonth(): Date
    moveToMonth(month: number, orient?: number): Date
    moveToNthOccurrence(dayOfWeek: number, occurrence: number): Date
    setTimeToNow(): Date
    setTimezone(offset: string): Date
    setTimezoneOffset(offset: number): Date
    toString(format?: string): string
    Deferred<T>(): JQueryDeferred<T>
  }
}

// Global scope declarations are only allowed in module contexts, so we
// need this to make Typescript think this is a module.
export {}
