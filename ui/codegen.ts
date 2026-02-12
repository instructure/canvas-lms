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

import type {CodegenConfig} from '@graphql-codegen/cli'

const config: CodegenConfig = {
  schema: './schema.graphql',
  documents: [
    'ui/**/*.tsx',
    'ui/**/*.ts',
    'ui/**/*.jsx',
    'ui/**/*.js',
    '!ui/**/__tests__/**/*',
    '!ui/**/*.test.*',
    '!ui/**/Mocks.*',
    '!ui/features/grade_summary/**/*',
    // Self-contained graphql modules with internal fragment systems - excluded to avoid duplicate names
    // TODO: Refactor these to use unique fragment names, then remove exclusions
    '!ui/features/discussion_topic_edit_v2/graphql/**/*',
    '!ui/features/discussion_topics_post/graphql/**/*',
    '!ui/shared/assignments/graphql/student/**/*',
    '!ui/shared/assignments/graphql/studentMocks.*',
    '!ui/shared/outcomes/react/treeBrowser.*',
  ],
  ignoreNoDocuments: true,
  generates: {
    './ui/shared/graphql/codegen/': {
      preset: 'client',
      presetConfig: {
        fragmentMasking: false,
      },
      config: {
        enumsAsTypes: true,
      },
    },
  },
}

export default config
