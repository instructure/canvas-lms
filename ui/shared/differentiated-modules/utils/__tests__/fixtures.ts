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

const fixtures = {
  name: `<div class="name" title="Module 1"></div>`,
  unlockAt: `<div class="unlock_at">Aug 2, 2023 at 12am</div>`,
  requiresSequentialProgress: `<div class="require_sequential_progress">true</div>`,
  publishFinalGrade: `<div class="publish_final_grade">true</div>`,
}

export function getFixture(moduleId: keyof typeof fixtures) {
  const element = document.createElement('div')
  element.innerHTML = fixtures[moduleId]
  element.setAttribute('data-module-id', '8')
  return element
}
