/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export type {
  GradingScheme,
  GradingSchemeTemplate,
  GradingSchemeDataRow,
  GradingSchemeUpdateRequest,
  GradingSchemeSummary,
} from './gradingSchemeApiModel'

export type {ApiCallStatus} from './react/hooks/ApiCallStatus'
export {useGradingSchemes} from './react/hooks/useGradingSchemes'
export {useGradingScheme} from './react/hooks/useGradingScheme'
export {useDefaultGradingScheme} from './react/hooks/useDefaultGradingScheme'
export {useGradingSchemeCreate} from './react/hooks/useGradingSchemeCreate'
export {useGradingSchemeUpdate} from './react/hooks/useGradingSchemeUpdate'
export {useGradingSchemeDelete} from './react/hooks/useGradingSchemeDelete'
export {useGradingSchemeSummaries} from './react/hooks/useGradingSchemeSummaries'
