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

/**
 * Alias for the `any` type to be used when migrating JavaScript to TypeScript. Use this to indicate that a cast to
 * any was done solely for converting to TypeScript.
 *
 * Uses of this type should eventually be refactored out, either by updating the logic to be type-safe, or by converting
 * it to a cast to regular `any` to indicate an intentional and necessary use of any.
 */
export type TsMigrationAny = any
