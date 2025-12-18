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

/**
 * This file provides the gql template literal function used by GraphQL query
 * files in the replicated/ directory. It's separated from dependenciesShims.ts
 * to avoid circular dependencies with graphqlQueryHooks.ts.
 *
 * The replicated/ directory is shared between Canvas and SpeedGrader, and this
 * shim allows each repo to provide its own gql implementation.
 */

import {gql} from '@apollo/client'
import type {DocumentNode as GqlTemplateStringType} from 'graphql'

export {gql, type GqlTemplateStringType}
