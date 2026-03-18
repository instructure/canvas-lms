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

// Legacy quiz log auditing types for gradual TypeScript migration

declare module '@canvas/quiz-legacy-client-apps/environment' {
  const Environment: any
  export default Environment
}

declare module '@canvas/quiz-legacy-client-apps/util/from_jsonapi' {
  function fromJSONAPI(payload: any, type: string, single?: boolean): any
  export default fromJSONAPI
}

declare module '@canvas/quiz-legacy-client-apps/util/pick_and_normalize' {
  function pickAndNormalize(obj: any, attrs: any): any
  export default pickAndNormalize
}

declare module '@canvas/quiz-legacy-client-apps/util/inflections' {
  const inflections: {
    camelize: (str: string, uppercase?: boolean) => string
  }
  export default inflections
}

declare module 'chai-assert-change' {
  const plugin: any
  export default plugin
}

export {}
