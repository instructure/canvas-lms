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
  requirementCount: `<div class="requirements_message" data-requirement-type="one"></div>`,
  requiresSequentialProgress: `<div class="require_sequential_progress">true</div>`,
  publishFinalGrade: `<div class="publish_final_grade">true</div>`,
  prerequisites: `
    <div class="prerequisite_criterion">
      <span class="id" style="display: none;">14</span>
      <span class="name" style="display: none;">Module A</span>
    </div>
    <div class="prerequisite_criterion">
      <span class="id" style="display: none;">15</span>
      <span class="name" style="display: none;">Module B</span>
    </div>
  `,
  requirements: `
    <div class="ig-row with-completion-requirements ig-published">
      <span class="item_name">
        <a title="HW 1" class="ig-title title item_link" href="/courses/13/modules/items/45">HW 1</a>
      </span>
      <span class="requirement_type min_score_requirement" style="display: none;"></span>
      <span class="requirement_type must_mark_done_requirement" style="display: block;"></span>
      <span class="points_possible_display">10 pts</span>
      <div class="module_item_icons nobr">
        <span class="type" style="display: none;">assignment</span>
        <span class="id" style="display: none;">93</span>
      </div>
    </div>
    <div class="ig-row with-completion-requirements ig-published">
      <span class="item_name">
        <a title="Quiz 1" class="ig-title title item_link" href="/courses/13/modules/items/54">Quiz 1</a>
      </span>
      <span class="requirement_type min_score_requirement" style="display: block;">
        <span class="min_score">70</span>
      </span>
      <span class="requirement_type must_mark_done_requirement" style="display: none;"></span>
      <div class="module_item_icons nobr">
        <span class="type" style="display: none;">quiz</span>
        <span class="id" style="display: none;">94</span>
      </div>
    </div>
  `,
}

export function getFixture(fixtureType: keyof typeof fixtures) {
  const element = document.createElement('div')
  element.innerHTML = fixtures[fixtureType]
  element.setAttribute('data-module-id', '8')
  return element
}
