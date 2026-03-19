//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

type GroupLike = {
  get: (key: string) => unknown
  users: () => {
    models: Array<{
      has: (key: string) => boolean
      get: (key: string) => unknown
    }>
  }
}

export default function groupHasSubmissions(group: GroupLike): boolean {
  return (
    Boolean(group.get('has_submission')) ||
    group.users().models.reduce((hasSubmission: boolean, user) => {
      const submissions = user.get('group_submissions')
      const hasGroupSubmissions = Array.isArray(submissions) && submissions.length > 0
      return hasSubmission || (user.has('group_submissions') && hasGroupSubmissions)
    }, false)
  )
}
