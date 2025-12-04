/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export interface AccountReport {
  id: string
  report: string
  status: 'created' | 'running' | 'compiling' | 'complete' | 'error' | 'aborted'
  created_at: string
  started_at?: string
  ended_at?: string
  progress: number
  run_time: number
  file_url?: string
  message?: string
  parameters?: {
    extra_text?: string
  }
  user?: {
    id: string
    display_name: string
    html_url: string
  }
}

export interface AccountReportInfo {
  report: string
  title: string
  description_html: string
  parameters_html?: string
  last_run?: AccountReport
}

export function reportRunning(status: string | undefined) {
  return status ? status === 'created' || status === 'running' || status === 'compiling' : false
}
