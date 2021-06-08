/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

// Webpack wants to be able to resolve every module before
// building.  Because we use a pitching loader for i18n tags,
// we never make it to the resource itself (or shouldn't). However,
// We need to give webpack a resource that exists on the Filesystem
// before the pitching i18n loader catches it, so we replace
// i18n!some-scope requires with i18n?some-scope!dummyI18nResource
throw 'Should never actually call this module'
