/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!course_wizard'
    /**
     * Returns an array containing all the possible items for the checklist
     * For many ListItems, the ! is added for the complete property
     *  because the ENV is checking if the step is nil? or empty?
     */
export default [
      {
        key:'content_import',
        complete: !ENV.COURSE_WIZARD.checklist_states.import_step,
        title: I18n.t("Import Content"),
        text: I18n.t("If you've been using another course management system, you probably have stuff in there that you're going to want moved over to Canvas. We can walk you through the process of easily migrating your content into Canvas."),
        url: ENV.COURSE_WIZARD.urls.content_import,
        iconClass: 'icon-upload'
      },
      {
        key:'add_assignments',
        complete: !ENV.COURSE_WIZARD.checklist_states.assignment_step,
        title: I18n.t("Add Course Assignments"),
        text: I18n.t("Add your assignments.  You can just make a long list, or break them up into groups - and even specify weights for each assignment group."),
        url: ENV.COURSE_WIZARD.urls.add_assignments,
        iconClass: 'icon-assignment'
      },
      {
        key:'add_students',
        complete: !ENV.COURSE_WIZARD.checklist_states.add_student_step,
        title: I18n.t("Add Students to the Course"),
        text: I18n.t("You'll definitely want some of these.  What's the fun of teaching a course if nobody's even listening?"),
        url: ENV.COURSE_WIZARD.urls.add_students,
        iconClass: 'icon-group-new'
      },
      {
        key:'add_files',
        complete: !ENV.COURSE_WIZARD.checklist_states.import_step, /* Super odd in the existing wizard this is set to display: none */
        title: I18n.t("Add Files to the Course"),
        text: I18n.t("The Files tab is the place to share lecture slides, example documents, study helps -- anything your students will want to download.  Uploading and organizing your files is easy with Canvas.  We'll show you how."),
        url: ENV.COURSE_WIZARD.urls.add_files,
        iconClass: 'icon-note-light'
      },
      {
        key:'select_navigation',
        complete: !ENV.COURSE_WIZARD.checklist_states.navigation_step,
        title: I18n.t("Select Navigation Links"),
        text: I18n.t("By default all links are enabled for a course.  Students won't see links to sections that don't have content.  For example, if you haven't created any quizzes, they won't see the quizzes link.  You can sort and explicitly disable these links if there are areas of the course you don't want your students accessing."),
        url: ENV.COURSE_WIZARD.urls.select_navigation,
        iconClass: 'icon-hamburger'
      },
      {
        key:'home_page',
        complete: ENV.COURSE_WIZARD.checklist_states.home_page_step,
        title: I18n.t("Choose a Course Home Page"),
        text: I18n.t("When people visit the course, this is the page they'll see.  You can set it to show an activity stream, the list of course modules, a syllabus, or a custom page you write yourself.  The default is the course activity stream."),
        iconClass: 'icon-home'
      },
      {
        key:'course_calendar',
        complete: !ENV.COURSE_WIZARD.checklist_states.calendar_event_step,
        title: I18n.t("Add Course Calendar Events"),
        text: I18n.t("Here's a great chance to get to know the calendar and add any non-assignment events you might have to the course. Don't worry, we'll help you through it."),
        url: ENV.COURSE_WIZARD.urls.course_calendar,
        iconClass: 'icon-calendar-month'
      },
      {
        key:'add_tas',
        complete: !ENV.COURSE_WIZARD.checklist_states.add_ta_step,
        title: I18n.t("Add TAs to the Course"),
        text: I18n.t("You may want to assign some TAs to help you with the course.  TAs can grade student submissions, help moderate the discussions and even update due dates and assignment details for you."),
        url: ENV.COURSE_WIZARD.urls.add_tas,
        iconClass: 'icon-educators'
      },
      {
        key:'publish_course',
        complete: ENV.COURSE_WIZARD.checklist_states.publish_step,
        title: I18n.t("Publish the Course"),
        text: I18n.t("All finished?  Time to publish your course!  Click the button below to make it official! Publishing will allow the users to begin participating in the course."),
        non_registered_text: I18n.t("This course is claimed and ready, but you'll need to finish the registration process before you can publish the course.  You should have received an email from Canvas with a link to finish the process.  Be sure to check your spam box."),
        iconClass: 'icon-publish icon-Solid'
      }
    ]
