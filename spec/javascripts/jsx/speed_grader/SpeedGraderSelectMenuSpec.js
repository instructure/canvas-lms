/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery';
import SpeedGraderHelpers from 'speed_grader_helpers';
import SpeedGraderSelectMenu from 'speed_grader_select_menu';

QUnit.module("SpeedGraderSelectMenu", () => {
  QUnit.module("#updateSelectMenuStatus", updateSelectMenuStatusHooks => {
    const students = [
      {
        index: 0,
        id: 4,
        name: 'Guy B. Studying',
        submission_state: 'not_graded',
        submission: { score: null, grade: null }
      },
      {
        index: 1,
        id: 12,
        name: 'Sil E. Bus',
        submission_state: 'graded',
        submission: { score: 7, grade: 70 }
      }
    ];

    const menuOptions = students.map(student => {
      const className = SpeedGraderHelpers.classNameBasedOnStudent(student);
      return {id: student.id, name: student.name, className, anonymizableId: 'id'};
    });

    const fixtureNode = document.getElementById("fixtures");

    let testArea;
    let selectMenu;

    updateSelectMenuStatusHooks.beforeEach(() => {
      testArea = document.createElement('div');
      testArea.id = "test_area";
      fixtureNode.appendChild(testArea);
      selectMenu = new SpeedGraderSelectMenu(menuOptions);
      selectMenu.appendTo(testArea);
    });

    updateSelectMenuStatusHooks.afterEach(() => {
      fixtureNode.innerHTML = "";
      $('.ui-selectmenu-menu').remove();
    });

    QUnit.module('without sections', () => {
      test('ignores null students', () => {
        selectMenu.updateSelectMenuStatus({student: null});
        ok(true, 'does not error');
      });

      test('updates status for current student', () => {
        const student = students[0];
        student.submission_state = 'graded';

        const status = $('.ui-selectmenu-status');

        let isCurrentStudent = false;
        const newStudentInfo = "Guy B. Studying – graded"
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})
        strictEqual(status.hasClass("graded"), false);

        isCurrentStudent = true;
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})
        strictEqual(status.hasClass("graded"), true);
      });

      test('updates to graded', () => {
        const student = students[0];
        student.submission_state = 'graded';
        const isCurrentStudent = false
        const newStudentInfo = "Guy B. Studying – graded"
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})

        const entry = selectMenu.data('selectmenu').list.find('li:eq(0)').children();
        strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check').length, 1);
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1);

        const option = $(selectMenu.option_tag_array[0]);
        strictEqual(option.hasClass("not_graded"), false);
        equal(option.text(), "Guy B. Studying – graded");
        strictEqual(option.hasClass("graded"), true);
      });

      test('updates to not_graded', function () {
        const student = students[1];
        student.submission_state = 'not_graded';
        const isCurrentStudent = false
        const newStudentInfo = "Sil E. Bus – not graded"
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})

        const entry = selectMenu.data('selectmenu').list.find('li:eq(1)').children();
        strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")').length, 1);
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Sil E. Bus")').length, 1);

        const option = $(selectMenu.option_tag_array[1]);
        strictEqual(option.hasClass("graded"), false);
        equal(option.text(), "Sil E. Bus – not graded");
        strictEqual(option.hasClass("not_graded"), true);
      });

      // We really never go to not_submitted, but a background update
      // *could* potentially do this, so we should handle it.
      test('updates to not_submitted', function () {
        const student = students[0];
        student.submission_state = 'not_submitted';
        selectMenu.updateSelectMenuStatus(student, false, "Guy B. Studying – not submitted");
        const isCurrentStudent = false
        const newStudentInfo = "Guy B. Studying – not submitted"
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})

        const entry = selectMenu.data('selectmenu').list.find('li:eq(0)').children();
        strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon').length, 1);
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1);

        const option = $(selectMenu.option_tag_array[0]);
        strictEqual(option.hasClass("graded"), false);
        equal(option.text(), "Guy B. Studying – not submitted");
        strictEqual(option.hasClass("not_submitted"), true);
      });

      // We really never go to resubmitted, but a backgroud update *could*
      // potentially do this, so we should handle it.
      test('updates to resubmitted', function () {
        const student = students[1];
        student.submission_state = 'resubmitted';
        student.submission.submitted_at = '2017-07-10T17:00:00Z';
        const isCurrentStudent = false
        const newStudentInfo = "Sil E. Bus – graded, then resubmitted (Jul 10 at 5pm)"
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})

        const entry = selectMenu.data('selectmenu').list.find('li:eq(0)').children();
        strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")').length, 1);
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1);

        const option = $(selectMenu.option_tag_array[1]);
        strictEqual(option.hasClass("not_graded"), false);
        equal(option.text(), "Sil E. Bus – graded, then resubmitted (Jul 10 at 5pm)");
        strictEqual(option.hasClass("resubmitted"), true);
      });

      // We really never go to not_gradable, but a backgroud update *could*
      // potentially do this, so we should handle it.
      test('updates to not_gradable', function () {
        const student = students[0];
        student.submission_state = 'not_gradeable';
        student.submission.submitted_at = '2017-07-10T17:00:00Z';
        const isCurrentStudent = false
        const newStudentInfo = "Sil E. Bus – graded"
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'})

        const entry = selectMenu.data('selectmenu').list.find('li:eq(0)').children();
        strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon > i.icon-check').length, 1);
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1)

        const option = $(selectMenu.option_tag_array[1]);
        strictEqual(option.hasClass("not_graded"), false);
        equal(option.text().trim(), "Sil E. Bus – graded");
        strictEqual(option.hasClass("graded"), true);
      });
    });

    QUnit.module("with sections", hooks => {
      let sections;
      hooks.beforeEach(() => {
        sections = {
          name: "Showing: Some stuff",
          options: [
            { id: "section_0", data: { "section-id": 0 }, name: "Show all sections", className: { raw: "section_0" } },
            { id: "section_123", data: { "section-id": 123 }, name: "Not everybody", className: { raw: "section_123" } }
          ],
        };
        menuOptions.unshift(sections);
      })

      test('updates the right student in the presence of sections', () => {
        const student = students[0];
        student.submission_state = 'graded';
        const isCurrentStudent = false
        const newStudentInfo = 'Guy B. Studying – graded'
        selectMenu.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId: 'id'});

        const entry = selectMenu.data('selectmenu').list.find('li:eq(0)').children();
        strictEqual(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check').length, 1);
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length, 1);

        const option = $(selectMenu.option_tag_array[0]);
        strictEqual(option.hasClass("not_graded"), false);
        equal(option.text(), "Guy B. Studying – graded");
        strictEqual(option.hasClass("graded"), true);
      });
    });
  });
});
