/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react';
import { mount } from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme';
import SearchResultsRow from 'jsx/gradebook-history/SearchResultsRow';

function mountComponent (props = {}) {
  const tbody = document.getElementById('search-results-tbody');
  return mount(<SearchResultsRow {...props} />, { attachTo: tbody });
}

QUnit.module('SearchResultsRow', {
  setup () {
    // can't insert <tr/> into a <div/>, so create a <tbody/> first
    const tbody = document.createElement('tbody');
    tbody.id = 'search-results-tbody';
    document.body.appendChild(tbody);

    this.item = {
      anonymous: false,
      assignment: 'Rustic Rubber Duck',
      date: '2017-05-30T23:16:59Z',
      displayAsPoints: true,
      grader: 'Ms. Lopez',
      gradeAfter: '21',
      gradeBefore: '19',
      gradeCurrent: '22',
      id: '123456',
      pointsPossibleBefore: '25',
      pointsPossibleAfter: '30',
      pointsPossibleCurrent: '30',
      student: 'Norval Abbott',
      time: '11:16pm'
    };
    this.wrapper = mountComponent({ item: this.item });
  },

  teardown () {
    const tbody = document.getElementById('search-results-tbody');
    this.wrapper.detach();
    tbody.remove();
  }
});

test('displays the history date', function () {
  const date = this.wrapper.find('td').nodes[0].innerText;
  strictEqual(date, 'May 30, 2017 at 11:16pm');
});

test('has text for when not anonymously graded', function () {
  const anonymous = this.wrapper.find('td').nodes[1].innerText;
  strictEqual(anonymous, 'Not anonymously graded');
});

test('has text for when anonymously graded', function () {
  const item = { ...this.item, anonymous: true };
  const wrapper = mountComponent({ item });
  const anonymous = wrapper.find('td').nodes[1].innerText;
  strictEqual(anonymous.trim(), 'Anonymously graded');
});

test('displays the history student', function () {
  const student = this.wrapper.find('td').nodes[2].innerText;
  strictEqual(student, this.item.student);
});

test('displays the history grader', function () {
  const grader = this.wrapper.find('td').nodes[3].innerText;
  strictEqual(grader, this.item.grader);
});

test('displays the history assignment', function () {
  const assignment = this.wrapper.find('td').nodes[4].innerText;
  strictEqual(assignment, this.item.assignment.toString());
});

test('displays the history grade before and points possible before if points based and grade is numeric', function () {
  const gradeBefore = this.wrapper.find('td').nodes[5].innerText;
  strictEqual(gradeBefore, "19/25");
});

test('displays only the history grade before if not points based', function () {
  this.item.displayAsPoints = false;
  this.wrapper = mountComponent({ item: this.item });
  const gradeBefore = this.wrapper.find('td').nodes[5].innerText;
  strictEqual(gradeBefore, "19");
});

test('displays only the history grade before if grade cannot be parsed as a number', function () {
  this.item.gradeBefore = "B";
  this.wrapper = mountComponent({ item: this.item });
  const gradeBefore = this.wrapper.find('td').nodes[5].innerText;
  strictEqual(gradeBefore, "B");
});

test('displays the history grade after and points possible after if points based and grade is numeric', function () {
  const gradeAfter = this.wrapper.find('td').nodes[6].innerText;
  strictEqual(gradeAfter, "21/30");
});

test('displays only the history grade after if not points based', function () {
  this.item.displayAsPoints = false;
  this.wrapper = mountComponent({ item: this.item });
  const gradeAfter = this.wrapper.find('td').nodes[6].innerText;
  strictEqual(gradeAfter, "21");
});

test('displays only the history grade after if grade cannot be parsed as a number', function () {
  this.item.gradeAfter = "B";
  this.wrapper = mountComponent({ item: this.item });
  const gradeAfter = this.wrapper.find('td').nodes[6].innerText;
  strictEqual(gradeAfter, "B");
});

test('displays the current grade and points possible if points based and grade is numeric', function () {
  const gradeCurrent = this.wrapper.find('td').nodes[7].innerText;
  strictEqual(gradeCurrent, "22/30");
});

test('displays only the history grade current if not points based', function () {
  this.item.displayAsPoints = false;
  this.wrapper = mountComponent({ item: this.item });
  const gradeCurrent = this.wrapper.find('td').nodes[7].innerText;
  strictEqual(gradeCurrent, "22");
});

test('displays only the history grade current if grade cannot be parsed as a number', function () {
  this.item.gradeCurrent = "B";
  this.wrapper = mountComponent({ item: this.item });
  const gradeCurrent = this.wrapper.find('td').nodes[7].innerText;
  strictEqual(gradeCurrent, "B");
});
