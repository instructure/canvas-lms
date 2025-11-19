# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# the keys in this hash correspond to the `group` values in permissions_registry.rb
# each must have a `label` and a `subtitle`. it can include `course_subtitle` if this
# should be different from the account one. it can optionally include help text in
# `details` and/or `considerations`, or `account_` or `course_` prefixed versions
# of those to display separate help text in each context.
PERMISSION_GROUPS = {
  manage_account_calendar: {
    label: -> { I18n.t("Manage Account Calendars") },
    subtitle: -> { I18n.t("add / edit / delete / change visibility") },
    account_details: [
      { title: -> { I18n.t("Account Calendars - add / edit / delete events") },
        description: -> { I18n.t("Allows user to add, edit, and delete events in account calendars.") } },
      { title: -> { I18n.t("Account Calendars - change visibility") },
        description: -> { I18n.t("Allows user to change visibility of account calendars.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Calendars") },
        description: -> { I18n.t("Even with the Account Calendars - add / edit / delete events permission enabled, events can only be created in account calendars that are visible.") } }
    ]
  },
  manage_assignments_and_quizzes: {
    label: -> { I18n.t("Manage Assignments and Quizzes") },
    subtitle: -> { I18n.t("add / delete / edit") },
    account_details: [
      { title: -> { I18n.t("Assignments and Quizzes - add") },
        description: -> { I18n.t("Allows user to add assignments in a course.") } },
      { description: -> { I18n.t("Allows user to add assignment groups in a course.") } },
      { description: -> { I18n.t("Allows user to duplicate assignments in a course.") } },
      { description: -> { I18n.t("Allows user to add new assignments to a module.") } },
      { description: -> { I18n.t("Allows user to add new question banks to a course or account.") } },
      { description: -> { I18n.t("Allows user to add new questions to new or existing question banks in a course or account.") } },
      { description: -> { I18n.t("Allows user to add quizzes in a course.") } },
      { description: -> { I18n.t("Allows user to duplicate quizzes in a course.") } },
      { title: -> { I18n.t("Assignments and Quizzes - edit") },
        description: -> { I18n.t("Allows user to edit and publish/unpublish assignments.") } },
      { description: -> { I18n.t("Allows user to manage assignment settings.") } },
      { description: -> { I18n.t("Allows user to weight assignment groups.") } },
      { description: -> { I18n.t("Allows user to edit lock settings on the Assignments and Quizzes index pages.") } },
      { description: -> { I18n.t("Allows user to share an assignment to Commons.") } },
      { description: -> { I18n.t("Allows user to share a quiz to Commons.") } },
      { description: -> { I18n.t("Determines visibility and management of the Question Banks link in Account Navigation.") } },
      { description: -> { I18n.t("Allows user to edit and publish/unpublish quizzes.") } },
      { description: -> { I18n.t("Allows user to edit question banks in a course or account.") } },
      { title: -> { I18n.t("Assignments and Quizzes - delete") },
        description: -> { I18n.t("Allows user to delete assignments in a course.") } },
      { description: -> { I18n.t("Allows user to delete assignment groups in a course.") } },
      { description: -> { I18n.t("Allows user to delete quizzes in a course.") } },
      { description: -> { I18n.t("Allows user to delete question banks in a course or account.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("To access the Assignments Index Page, Course Content - view must be enabled.") } },
      { description: -> { I18n.t("To differentiate assignments to individual students, Users - view list must also be enabled.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("To edit lock settings from the Assignments index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.") } },
      { description: -> { I18n.t("If Blueprint Courses - add / edit / associate / delete and Courses - manage are enabled, but Assignments and Quizzes - edit is not enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.") } },
      { description: -> { I18n.t("To edit lock settings on an individual quiz, or on the Quizzes index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("These permissions do not manage Discussions. Discussions are managed via individual Discussion permissions.") } },
      { description: -> { I18n.t("To edit assignment details on individual discussions, Discussions - manage must also be enabled.") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To manage moderated grading, Grades - Select final grade for moderation must also be enabled.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("To access the Quizzes Index Page, Course Content - view must be enabled.") } },
      { description: -> { I18n.t("To moderate a quiz, Grades - edit must also be enabled.") } },
      { description: -> { I18n.t("To access item banks for a course or account, Item Banks - manage account must also be enabled.") } },
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("Disabling the Assignments and Quizzes - add permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating rubrics for an individual assignment.") } },
      { description: -> { I18n.t("Disabling the Assignments and Quizzes - edit permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing users from editing rubrics from an individual assignment.") } },
      { description: -> { I18n.t("Disabling the Assignments and Quizzes - delete permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from deleting rubrics for an individual assignment.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Assignments and Quizzes - add") },
        description: -> { I18n.t("Allows user to add assignments in a course.") } },
      { description: -> { I18n.t("Allows user to add assignment groups in a course.") } },
      { description: -> { I18n.t("Allows user to duplicate assignments in a course.") } },
      { description: -> { I18n.t("Allows user to add new assignments to a module.") } },
      { description: -> { I18n.t("Allows user to add new question banks to a course.") } },
      { description: -> { I18n.t("Allows user to add new questions to new or existing question banks in a course.") } },
      { description: -> { I18n.t("Allows user to add quizzes in a course.") } },
      { description: -> { I18n.t("Allows user to duplicate quizzes in a course.") } },
      { title: -> { I18n.t("Assignments and Quizzes - edit") },
        description: -> { I18n.t("Allows user to edit and publish/unpublish assignments.") } },
      { description: -> { I18n.t("Allows user to manage assignment settings.") } },
      { description: -> { I18n.t("Allows user to weight assignment groups.") } },
      { description: -> { I18n.t("Allows user to edit lock settings on the Assignments and Quizzes index pages.") } },
      { description: -> { I18n.t("Allows user to share an assignment to Commons.") } },
      { description: -> { I18n.t("Allows user to share a quiz to Commons.") } },
      { description: -> { I18n.t("Allows user to edit and publish/unpublish quizzes.") } },
      { title: -> { I18n.t("Assignments and Quizzes - delete") },
        description: -> { I18n.t("Allows user to delete assignments in a course.") } },
      { description: -> { I18n.t("Allows user to delete assignment groups in a course.") } },
      { description: -> { I18n.t("Allows user to delete quizzes in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Assignments") },
        description: -> { I18n.t("To differentiate assignments to individual students, Users - view list must also be enabled.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("To edit lock settings from the Assignments index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.") } },
      { description: -> { I18n.t("If Blueprint Courses - add / edit / associate / delete and Courses - manage are enabled, but Assignments and Quizzes - edit is not enabled, blueprint lock settings for an assignment can be managed from the assignment’s details page.") } },
      { description: -> { I18n.t("To edit lock settings on an individual quiz, or on the Quizzes index page, Blueprint Courses - add / edit / associate / delete and Courses - manage must also be enabled.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("To import assignments and quizzes using the Course Import Tool, Course Content - add / edit / delete must be enabled.") } },
      { title: -> { I18n.t("Discussions") },
        description: -> { I18n.t("These permissions do not manage Discussions. Discussions are managed via individual Discussion permissions.") } },
      { description: -> { I18n.t("To edit assignment details on individual discussions, Discussions - manage must also be enabled.") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To manage moderated grading, Grades - Select final grade for moderation must also be enabled.") } },
      { title: -> { I18n.t("Quizzes") },
        description: -> { I18n.t("To access the Quizzes Index Page, Course Content - view must be enabled.") } },
      { description: -> { I18n.t("To edit quizzes, Assignments and Quizzes - manage / edit must also be enabled.") } },
      { description: -> { I18n.t("To access item banks for a course, Item Banks - manage account must also be enabled.") } },
      { description: -> { I18n.t("To moderate a quiz, Grades - edit must also be enabled.") } },
      { title: -> { I18n.t("Rubrics") },
        description: -> { I18n.t("Disabling the Assignments and Quizzes - add permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from creating rubrics for an individual assignment.") } },
      { description: -> { I18n.t("Disabling the Assignments and Quizzes - edit permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing users from editing rubrics from an individual assignment.") } },
      { description: -> { I18n.t("Disabling the Assignments and Quizzes - delete permission will override (if enabled) the Rubrics - add / edit / delete permission, preventing user from deleting rubrics for an individual assignment.") } }
    ]
  },
  manage_course_content: {
    label: -> { I18n.t("Manage Course Content") },
    subtitle: -> { I18n.t("add / delete / edit") },
    details: [
      { title: -> { I18n.t("Course Content - add") },
        description: -> { I18n.t("Allows user to share course items directly with other users.") } },
      { description: -> { I18n.t("Allows user to copy individual course items to another course.") } },
      { description: -> { I18n.t("Allows user to view course copy status.") } },
      { description: -> { I18n.t("Allows user to create content migrations.") } },
      { description: -> { I18n.t("Allows user to create blackout dates.") } },
      { description: -> { I18n.t("Allows user to add events to Calendar List View Dashboard via the Add to Student To-Do checkbox. ") } },
      { description: -> { I18n.t("Allows user to create a course pace via Course Pacing.") } },
      { description: -> { I18n.t("Allows user to import resources from Commons into a course.") } },
      { description: -> { I18n.t("Allows user to import content using the Course Import Tool.") } },
      { description: -> { I18n.t("Allows user to add non-graded discussions to List View Dashboard via the Add to Student To-Do checkbox.") } },
      { description: -> { I18n.t("Allows user to create, add items, and duplicate modules.") } },
      { description: -> { I18n.t("Allows user to add pages to List View Dashboard via the Add to Student To-Do checkbox.") } },
      { title: -> { I18n.t("Course Content - edit") },
        description: -> { I18n.t("Allows user to lock / unlock selected announcements individually or in bulk.") } },
      { description: -> { I18n.t("Allows user to edit a list of assignment blackout dates.") } },
      { description: -> { I18n.t("Allows user to share assignments to Commons or edit previously shared content.") } },
      { description: -> { I18n.t("Allows user to edit to-do date on a course Page that supports it.") } },
      { description: -> { I18n.t("Allows user to edit Conferences.") } },
      { description: -> { I18n.t("Allows user to edit title, and description on all collaborations.") } },
      { description: -> { I18n.t("Allows user to update modules (edit module settings, publish, unpublish, batch edit, assign modules).") } },
      { description: -> { I18n.t("Allows user to edit content migrations.") } },
      { description: -> { I18n.t("Allows user to edit and publish a course pace via Course Pacing.") } },
      { description: -> { I18n.t("Allows user to edit the course syllabus.") } },
      { description: -> { I18n.t("Allows user to edit course tabs.") } },
      { title: -> { I18n.t("Course Content - delete") },
        description: -> { I18n.t("Allows user to remove selected announcements individually or in bulk.") } },
      { description: -> { I18n.t("Allows user to remove assignment blackout dates.") } },
      { description: -> { I18n.t("Allows user to remove collaborators on all collaborations.") } },
      { title: -> { I18n.t("Course Content - add / edit / or delete") },
        description: -> { I18n.t("Allows user to have full section visibility when viewing announcements.") } },
      { description: -> { I18n.t("Allows user to access the Attendance tool.") } },
      { description: -> { I18n.t("Allows user to view Course Status, Choose Home Page, and Course Setup Checklist buttons in the Home page.") } },
      { description: -> { I18n.t("Allows user to access the Chat tool.") } },
      { description: -> { I18n.t("Allows user to view course Conferences.") } },
      { description: -> { I18n.t("Allows user to view and list content migrations.") } },
      { description: -> { I18n.t("Allows user to view a content migration content list by type.") } },
      { description: -> { I18n.t("Allows user access to LTI sub navigation tool selection for assignment syllabus configuration.") } },
      { description: -> { I18n.t("Allows user to view or retrieve a list of assignment blackout dates.") } },
      { description: -> { I18n.t("Allows user to view a content migration notice to an \"import in progress\".") } },
      { description: -> { I18n.t("Allows user to view previously created collaborations.") } },
      { description: -> { I18n.t("Allows user to view and list course paces via Course Pacing.") } },
      { description: -> { I18n.t("Allows user to view and initiate course link validation.") } }
    ],
    considerations: [
      { title: -> { I18n.t("Attendance") },
        description: -> { I18n.t("The Attendance tool must be enabled by your Canvas admin.") } },
      { title: -> { I18n.t("Chat") },
        description: -> { I18n.t("The Chat tool must be enabled by your Canvas admin.") } },
      { title: -> { I18n.t("Commons") },
        description: -> { I18n.t("To share a Discussion to Commons, Discussions - view must also be enabled.") } },
      { title: -> { I18n.t("Course Home Page") },
        description: -> { I18n.t("Teachers, designers, and TAs can select a course home page without the Course content - add / edit / delete permission.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("The Course Status buttons (unpublished and published) are only displayed until a student submission is received. Courses cannot be unpublished with student submissions.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("Module items cannot be unpublished if there are student submissions.") } },
      { title: -> { I18n.t("Course Pacing") },
        description: -> { I18n.t("Course Pacing feature preview must be enabled in your institution.") } }
    ]
  },
  manage_course_designer_enrollments: {
    label: -> { I18n.t("Users - Designers") },
    subtitle: -> { I18n.t("add / remove in courses") },
    account_details: [
      { title: -> { I18n.t("Designers - add") },
        description: -> { I18n.t("Allows user to add designers to a course from the account Courses page.") } },
      { description: -> { I18n.t("Allows user to add designers to a course.") } },
      { title: -> { I18n.t("Designers - remove") },
        description: -> { I18n.t("Allows user to remove designers from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate designers in a course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Courses (Account)") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add designers to a course from the Courses page via email address or login ID even if a designer does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("To access the account Courses page, Courses - view list must be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Designers - add") },
        description: -> { I18n.t("Allows user to add designers to a course.") } },
      { title: -> { I18n.t("Designers - remove") },
        description: -> { I18n.t("Allows user to remove designers from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate designers in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add designers to a course from the People page via email address or login ID even if a designer does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ]
  },
  manage_course_observer_enrollments: {
    label: -> { I18n.t("Users - Observers") },
    subtitle: -> { I18n.t("add / remove in courses") },
    account_details: [
      { title: -> { I18n.t("Observers - add") },
        description: -> { I18n.t("Allows user to add observers to a course from the account Courses page.") } },
      { description: -> { I18n.t("Allows user to add observers to a course.") } },
      { title: -> { I18n.t("Observers - remove") },
        description: -> { I18n.t("Allows user to remove observers from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate observers in a course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Courses (Account)") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add observers to a course from the Courses page via email address or login ID even if an observer does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("To access the account Courses page, Courses - view list must be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Observers - add") },
        description: -> { I18n.t("Allows user to add observers to a course.") } },
      { title: -> { I18n.t("Observers - remove") },
        description: -> { I18n.t("Allows user to remove observers from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate observers in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add observers to a course from the People page via email address or login ID even if an observer does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ]
  },
  manage_course_student_enrollments: {
    label: -> { I18n.t("Users - Students") },
    subtitle: -> { I18n.t("add / remove in courses") },
    account_details: [
      { title: -> { I18n.t("Students - add") },
        description: -> { I18n.t("Allows user to add students to a course from the account Courses page.") } },
      { description: -> { I18n.t("Allows user to update a student’s section enrollment or role.") } },
      { description: -> { I18n.t("Allows user to add students to a course.") } },
      { title: -> { I18n.t("Students - remove") },
        description: -> { I18n.t("Allows user to remove students from a course.") } },
      { description: -> { I18n.t("Allows user to remove a student’s section enrollment or role.") } },
      { description: -> { I18n.t("Allows user to deactivate students in a course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Courses (Account)") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add students to a course from the Courses page via email address or login ID even if a student does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("To access the account Courses page, Courses - view list must be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Students - add") },
        description: -> { I18n.t("Allows user to add students to a course.") } },
      { description: -> { I18n.t("Allows user to update a student’s section enrollment or role.") } },
      { title: -> { I18n.t("Students - remove") },
        description: -> { I18n.t("Allows user to remove students from a course.") } },
      { description: -> { I18n.t("Allows user to remove a student’s section enrollment or role.") } },
      { description: -> { I18n.t("Allows user to deactivate students in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add students to a course from the People page via email address or login ID even if a student does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ]
  },
  manage_course_ta_enrollments: {
    label: -> { I18n.t("Users - TAs") },
    subtitle: -> { I18n.t("add / remove in courses") },
    account_details: [
      { title: -> { I18n.t("TAs - add") },
        description: -> { I18n.t("Allows user to add TAs to a course from the account Courses page.") } },
      { description: -> { I18n.t("Allows user to add TAs in the course.") } },
      { title: -> { I18n.t("TAs - remove") },
        description: -> { I18n.t("Allows user to remove TAs from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate TAs in a course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Courses (Account)") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add TAs to a course from the Courses page via email address or login ID even if a TA does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("To access the account Courses page, Courses - view list must be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("TAs - add") },
        description: -> { I18n.t("Allows user to add TAs in the course.") } },
      { title: -> { I18n.t("TAs - remove") },
        description: -> { I18n.t("Allows user to remove TAs from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate TAs in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add TAs to a course from the People page via email address or login ID even if a TA does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ]
  },
  manage_course_teacher_enrollments: {
    label: -> { I18n.t("Users - Teachers") },
    subtitle: -> { I18n.t("add / remove in courses") },
    account_details: [
      { title: -> { I18n.t("Teachers - add") },
        description: -> { I18n.t("Allows user to add teachers to a course from the account Courses page.") } },
      { description: -> { I18n.t("Allows user to add teachers to a course.") } },
      { title: -> { I18n.t("Teachers - remove") },
        description: -> { I18n.t("Allows user to remove teachers from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate teachers in a course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Courses (Account)") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add teachers to a course from the Courses page via email address or login ID even if a teacher does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("To access the account Courses page, Courses - view list must be enabled.") } },
      { title: -> { I18n.t("People (Course)") },
        description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Teachers - add") },
        description: -> { I18n.t("Allows user to add teachers to a course.") } },
      { title: -> { I18n.t("Teachers - remove") },
        description: -> { I18n.t("Allows user to remove teachers from a course.") } },
      { description: -> { I18n.t("Allows user to deactivate teachers in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("People") },
        description: -> { I18n.t("If the Open Registration account setting is enabled, users with this permission can add teachers to a course from the People page via email address or login ID even if a teacher does not already have a Canvas account.") } },
      { description: -> { I18n.t("To add a user via SIS ID, SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("If an enrollment is created via SIS, only admins can remove the enrollment from a course.") } },
      { description: -> { I18n.t("To remove a user via SIS ID, SIS Data - manage must also be enabled.") } }
    ]
  },
  manage_course_templates: {
    label: -> { I18n.t("Manage Course Templates") },
    subtitle: -> { I18n.t("create / delete / edit") },
    account_details: [
      { title: -> { I18n.t("Course Templates - create") },
        description: -> { I18n.t("Allows user to set a template for an account.") } },
      { description: -> { I18n.t("Allows user to select a course as a course template in Course Settings.") } },
      { description: -> { I18n.t("Allows user to view names of course templates in the root account.") } },
      { title: -> { I18n.t("Course Templates - delete") },
        description: -> { I18n.t("Allows user to remove a course as a course template in Course Settings.") } },
      { description: -> { I18n.t("Allows user to set an account to not use a template.") } },
      { title: -> { I18n.t("Course Templates - edit") },
        description: -> { I18n.t("Allows user to change the template being used by an account.") } },
      { description: -> { I18n.t("Allows user to view names of course templates in the root account.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Account Settings") },
        description: -> { I18n.t("To access the Account Settings tab, Account-level settings - manage must also be enabled.") } },
      { title: -> { I18n.t("Courses") },
        description: -> { I18n.t("To create a new course to use as a course template, Courses - add must also be enabled.") } }
    ]
  },
  manage_courses: {
    label: -> { I18n.t("Manage Courses") },
    subtitle: -> { I18n.t("add / manage / conclude / delete / publish / reset") },
    course_subtitle: -> { I18n.t("conclude / delete / publish / reset") },
    account_details: [
      { title: -> { I18n.t("Courses - add") },
        description: -> { I18n.t("Allows user to add new courses to an account.") } },
      { title: -> { I18n.t("Courses - manage") },
        description: -> { I18n.t("Allows user to sync Blueprint Courses.") } },
      { description: -> { I18n.t("Allows user to view Blueprint Sync history.") } },
      { description: -> { I18n.t("Allows user to view and manage courses in the account.") } },
      { description: -> { I18n.t("Allows user to view the Course Setup Checklist button.") } },
      { description: -> { I18n.t("Allows user to access the Navigation tab.") } },
      { description: -> { I18n.t("Allows user to edit course image, name, course code, time zone, subaccount, term, and other options in Course Details tab.") } },
      { description: -> { I18n.t("Allows user to access Student View (test student), Copy this Course, and Permanently Delete Course buttons.") } },
      { description: -> { I18n.t("Allows user to view student context cards in announcement and discussion replies.") } },
      { title: -> { I18n.t("Courses - conclude") },
        description: -> { I18n.t("Allows user to view the Conclude Course button.") } },
      { title: -> { I18n.t("Courses - delete") },
        description: -> { I18n.t("Allows user to view the Delete this Course button.") } },
      { title: -> { I18n.t("Courses - publish") },
        description: -> { I18n.t("Allows user to view the Publish Course and Unpublish Course buttons in the Course Home page. Allows user to view the Publish button in a course card for an unpublished course (Card View Dashboard).") } },
      { title: -> { I18n.t("Courses - reset") },
        description: -> { I18n.t("Allows user to view the Reset Course Content button.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("If Courses - manage is enabled, but Blueprint Courses - add / edit / associate / delete is not enabled, users can still sync Blueprint Courses and view Sync history.") } },
      { title: -> { I18n.t("Courses - Account Settings") },
        description: -> { I18n.t("To access the Courses link in Account Navigation, Courses - view list must be enabled.") } },
      { description: -> { I18n.t("To add a course, Courses - add must also be enabled.") } },
      { description: -> { I18n.t("To restore a deleted course, Courses - delete, Courses - undelete, and Course Content - view must also be enabled.") } },
      { title: -> { I18n.t("Course Content") },
        description: -> { I18n.t("To manage course content, Courses - manage and Course Content - add / edit / delete must be enabled.") } },
      { description: -> { I18n.t("To view Choose Home Page and Course Setup Checklist buttons, Courses - manage and Course Content - view must also be enabled. (Teachers, designers, and TAs can set the home page of a course, regardless of their permissions.)") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("The Courses - delete permission affects viewing the Permanently Delete this Course button, which only appears for manually created courses.") } },
      { description: -> { I18n.t("To cross-list a section, Courses - manage and Manage Course Sections - edit must also be enabled.") } },
      { description: -> { I18n.t("To edit the course SIS ID, Courses - manage and SIS Data - manage must also be enabled.") } },
      { description: -> { I18n.t("The Courses - Reset permission resets course content for both manually created and SIS-managed courses. (For SIS-managed courses, the SIS Data - manage permission does not apply.)") } },
      { title: -> { I18n.t("Courses - Account Navigations") },
        description: -> { I18n.t("To access the Courses link in Account Navigation, Courses - manage and Courses - view list must be enabled.") } },
      { title: -> { I18n.t("Grades") },
        description: -> { I18n.t("To view grades in a course, Courses - manage and Grades - view all grades must also be enabled.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("The Courses - publish permission allows the user to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete must be enabled.") } },
      { title: -> { I18n.t("Student Context Cards") },
        description: -> { I18n.t("Student context cards must be enabled for an account by an admin. If Courses - manage is not enabled, users can still view context cards through the Gradebook.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Courses - conclude") },
        description: -> { I18n.t("Allows user to view the Conclude Course button.") } },
      { title: -> { I18n.t("Courses - delete") },
        description: -> { I18n.t("Allows user to view the Delete this Course button.") } },
      { title: -> { I18n.t("Courses - publish") },
        description: -> { I18n.t("Allows user to view the Publish Course and Unpublish Course buttons in the Course Home page.") } },
      { description: -> { I18n.t("Allows user to view the Publish button in a course card for an unpublished course (Card View Dashboard).") } },
      { title: -> { I18n.t("Courses - reset") },
        description: -> { I18n.t("Allows user to view the Reset Course Content button.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Blueprint courses must be enabled for an account by an admin. Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("The Courses - delete permission affects viewing the Permanently Delete this Course button, which only appears for manually created courses.") } },
      { description: -> { I18n.t("The Courses - Reset permission resets course content for both manually created and SIS-managed courses. (For SIS-managed courses, the SIS Data - manage permission does not apply.)") } },
      { title: -> { I18n.t("Courses") },
        description: -> { I18n.t("Courses can only be created at the course level if allowed by a Canvas admin. If allowed, courses can be created in the Dashboard.") } },
      { title: -> { I18n.t("Modules") },
        description: -> { I18n.t("The Courses - publish permission allows the user to publish courses that do not contain modules. To publish/unpublish module content, Course Content - add / edit / delete must be enabled.") } }
    ]
  },
  manage_differentiation_tags: {
    label: -> { I18n.t("Manage Differentiation Tags") },
    subtitle: -> { I18n.t("add / delete / manage") },
    course_details: [
      { title: -> { I18n.t("Overview") },
        description: -> { I18n.t("These permissions control the ability to create, edit, and delete differentiation tags.") } },
      { title: -> { I18n.t("Warning") },
        description: -> { I18n.t("If any of these permissions are granted to a user role, that role will be able to view and access data about differentiation tags.") } }
    ]
  },
  manage_files: {
    label: -> { I18n.t("Manage Course Files") },
    subtitle: -> { I18n.t("add / delete / edit") },
    details: [
      { title: -> { I18n.t("Course Files - add") },
        description: -> { I18n.t("Allows user to add course files and folders.") } },
      { description: -> { I18n.t("Allows user to import a zip file.") } },
      { title: -> { I18n.t("Course Files - edit") },
        description: -> { I18n.t("Allows user to edit course files and folders.") } },
      { title: -> { I18n.t("Course Files - delete") },
        description: -> { I18n.t("Allows user to delete course files and folders.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Course Files") },
        description: -> { I18n.t("If one or all permissions are disabled, user can still view and download files into a zip file.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("To import files using the Course Import Tool, Course files - add and Course Content - add / edit / delete must be enabled.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("To edit lock settings for course files, Course files - edit, Blueprint Courses - add / edit / associate / delete, and Courses - manage must also be enabled.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Course Files") },
        description: -> { I18n.t("If one or all permissions are disabled, user can still view and download files into a zip file.") } },
      { title: -> { I18n.t("Course Settings") },
        description: -> { I18n.t("To import files using the Course Import Tool, Course files - add and Course Content - add / edit / delete must be enabled.") } },
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Blueprint courses must be enabled for an account by an admin.") } },
      { description: -> { I18n.t("Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.") } }
    ]
  },
  manage_groups: {
    label: -> { I18n.t("Manage Groups") },
    subtitle: -> { I18n.t("add / delete / manage") },
    account_details: [
      { title: -> { I18n.t("Groups - add") },
        description: -> { I18n.t("Allows user to create account or course groups.") } },
      { description: -> { I18n.t("Allows user to add group members to account or course groups.") } },
      { description: -> { I18n.t("Allows user to add a group for a group assignment in a course.") } },
      { description: -> { I18n.t("Allows user to create course groups created by students.") } },
      { description: -> { I18n.t("Allows users to import groups in a course.") } },
      { title: -> { I18n.t("Groups - delete") },
        description: -> { I18n.t("Allows user to delete account or course groups.") } },
      { description: -> { I18n.t("Allows user to remove students from account or course groups.") } },
      { description: -> { I18n.t("Allows user to move group members to another group in an account or course.") } },
      { description: -> { I18n.t("Allows user to assign a student group leader in an account or course.") } },
      { title: -> { I18n.t("Groups - manage") },
        description: -> { I18n.t("Allows user to edit account and course groups.") } },
      { description: -> { I18n.t("Allows user to view the Clone Group Set button for an account or course group.") } },
      { description: -> { I18n.t("Allows user to randomly assign users to an account or course group.") } },
      { description: -> { I18n.t("Allows user to add users to an account or course group.") } },
      { description: -> { I18n.t("Allows user to move group members to another group in an account or course.") } },
      { description: -> { I18n.t("Allows user to assign a student group leader in an account or course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Groups - add") },
        description: -> { I18n.t("To add account level groups via CSV, SIS Data - import must also be enabled.") } },
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("If this permission is disabled, at the account level, the user cannot view any existing account groups. At the course level, the user can view, but not access, any existing groups, including groups created by students.") } },
      { description: -> { I18n.t("To view account-level groups, Users - view list must also be enabled.") } },
      { description: -> { I18n.t("To view all student groups in a course, Groups - view all student groups must also be enabled.") } },
      { description: -> { I18n.t("By default, students can always create groups in a course. To restrict students from creating groups, Courses - manage must be enabled, and the Let students organize their own groups checkbox in Course Settings must not be selected.") } },
      { description: -> { I18n.t("To access the People page and view course groups, Users - view list must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Groups - add") },
        description: -> { I18n.t("Allows user to create course groups.") } },
      { description: -> { I18n.t("Allows user to add students to course groups.") } },
      { description: -> { I18n.t("Allows user to add a group for a group assignment in a course.") } },
      { description: -> { I18n.t("Allows user to create course groups created by students.") } },
      { description: -> { I18n.t("Allows users to import groups in a course.") } },
      { title: -> { I18n.t("Groups - delete") },
        description: -> { I18n.t("Allows user to delete course groups.") } },
      { description: -> { I18n.t("Allows user to remove group members from course groups.") } },
      { description: -> { I18n.t("Allows user to move group members to another group in a course.") } },
      { description: -> { I18n.t("Allows user to assign a student group leader in a course.") } },
      { title: -> { I18n.t("Groups - manage") },
        description: -> { I18n.t("Allows user to edit course groups.") } },
      { description: -> { I18n.t("Allows user to view the Clone Group Set button for a course group.") } },
      { description: -> { I18n.t("Allows user to randomly assign users to a course group.") } },
      { description: -> { I18n.t("Allows user to add users to a course group.") } },
      { description: -> { I18n.t("Allows user to move group members to another group in a course.") } },
      { description: -> { I18n.t("Allows user to assign a student group leader in a course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Groups") },
        description: -> { I18n.t("To view all student groups in a course, Groups - view all student groups must also be enabled.") } },
      { description: -> { I18n.t("By default, students can always create groups in a course. To restrict students from creating groups, Courses - manage must be enabled, and the Let students organize their own groups checkbox in Course Settings must not be selected.") } },
      { description: -> { I18n.t("To access the People page and view course groups, Users - view list must also be enabled.") } }
    ]
  },
  manage_lti: {
    label: -> { I18n.t("Manage LTI") },
    subtitle: -> { I18n.t("add / delete / edit") },
    account_details: [
      { title: -> { I18n.t("LTI - add") },
        description: -> { I18n.t("Allows user to manually add an app in Account Settings.") } },
      { description: -> { I18n.t("Allows user to add external app icons to the Rich Content Editor toolbar.") } },
      { description: -> { I18n.t("Allows user to manually add an app in Course Settings.") } },
      { title: -> { I18n.t("LTI - delete") },
        description: -> { I18n.t("Allows user to manually delete an app in Account Settings.") } },
      { description: -> { I18n.t("Allows user to manually delete an app in Course Settings.") } },
      { title: -> { I18n.t("LTI - edit") },
        description: -> { I18n.t("Allows user to edit configurations for manually added external apps.") } }
    ],
    course_details: [
      { title: -> { I18n.t("LTI - add") },
        description: -> { I18n.t("Allows user to manually add an app in Course Settings.") } },
      { title: -> { I18n.t("LTI - delete") },
        description: -> { I18n.t("Allows user to manually delete an app in Course Settings.") } },
      { title: -> { I18n.t("LTI - edit") },
        description: -> { I18n.t("Allows user to edit configurations for manually added external apps.") } }
    ],
    considerations: [
      { title: -> { I18n.t("External Apps") },
        description: -> { I18n.t("If LTI - add is disabled, users can still install approved apps through the Canvas App Center (if enabled for your institution). However, if LTI - delete is not enabled, they cannot delete manually added external apps.") } }
    ]
  },
  manage_sections: {
    label: -> { I18n.t("Manage Course Sections") },
    subtitle: -> { I18n.t("add / delete / edit") },
    account_details: [
      { title: -> { I18n.t("Course Sections - add") },
        description: -> { I18n.t("Allows user to add course sections in Course Settings.") } },
      { title: -> { I18n.t("Course Sections - edit") },
        description: -> { I18n.t("Allows user to rename course sections.") } },
      { description: -> { I18n.t("Allows user to change start and end dates for course sections.") } },
      { description: -> { I18n.t("Allows user to cross-list sections.") } },
      { title: -> { I18n.t("Course Sections - delete") },
        description: -> { I18n.t("Allows user to delete course sections.") } },
      { description: -> { I18n.t("Allows user to delete a user from a course section.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Cross-Listing") },
        description: -> { I18n.t("To cross-list sections, Course Sections - edit and Courses - manage must also be enabled.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Course Sections - add") },
        description: -> { I18n.t("Allows user to add course sections in Course Settings.") } },
      { title: -> { I18n.t("Course Sections - edit") },
        description: -> { I18n.t("Allows user to rename course sections. Allows user to change start and end dates for course sections. Allows user to cross-list sections.") } },
      { title: -> { I18n.t("Course Sections - delete") },
        description: -> { I18n.t("Allows user to delete course sections.") } },
      { description: -> { I18n.t("Allows user to delete a user from a course section.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Cross-Listing") },
        description: -> { I18n.t("To cross-list sections, Course Sections - edit must be enabled. The user must also be enrolled as an instructor in the courses being cross-listed.") } }
    ]
  },
  manage_wiki: {
    label: -> { I18n.t("Manage Pages") },
    subtitle: -> { I18n.t("create / delete / update") },
    account_details: [
      { title: -> { I18n.t("Pages - create") },
        description: -> { I18n.t("Allows user to create course pages.") } },
      { title: -> { I18n.t("Pages - delete") },
        description: -> { I18n.t("Allows user to delete course pages.") } },
      { title: -> { I18n.t("Pages - update") },
        description: -> { I18n.t("Allows user to edit course pages.") } },
      { description: -> { I18n.t("Allows user to define users allowed to edit the page.") } },
      { description: -> { I18n.t("Allows user to add page to student to-do list.") } },
      { description: -> { I18n.t("Allows user to publish and unpublish pages.") } },
      { description: -> { I18n.t("Allows user to view page history and set front page.") } },
      { description: -> { I18n.t("Allows user to edit Blueprint Course lock settings in the Pages index page and for an individual page in a Blueprint master course.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Blueprint courses must be enabled for an account by an admin.") } },
      { description: -> { I18n.t("To edit lock settings on the Pages index page, Pages - update, Blueprint Courses - add / edit / associate / delete, and Courses - manage.") } },
      { description: -> { I18n.t("However, if these additional permissions are enabled, but the Pages - update permission is not enabled, the user can still adjust content lock settings on individual pages in a Blueprint Master Course.") } },
      { title: -> { I18n.t("Student Page History") },
        description: -> { I18n.t("Students can edit and view page history if allowed in the options for an individual page.") } }
    ],
    course_details: [
      { title: -> { I18n.t("Pages - create") },
        description: -> { I18n.t("Allows user to create course pages.") } },
      { description: -> { I18n.t("Allows user to edit Blueprint lock settings for individual pages in a Blueprint Master Course.") } },
      { title: -> { I18n.t("Pages - delete") },
        description: -> { I18n.t("Allows user to delete course pages.") } },
      { description: -> { I18n.t("Allows user to edit Blueprint lock settings for individual pages in a Blueprint Master Course.") } },
      { title: -> { I18n.t("Pages - update") },
        description: -> { I18n.t("Allows user to edit course pages.") } },
      { description: -> { I18n.t("Allows user to define users allowed to edit the page.") } },
      { description: -> { I18n.t("Allows user to add page to student to-do list.") } },
      { description: -> { I18n.t("Allows user to publish and unpublish pages.") } },
      { description: -> { I18n.t("Allows user to view page history and set front page.") } },
      { description: -> { I18n.t("Allows user to edit Blueprint lock settings in the Pages index page and for an individual page in a Blueprint master course.") } }
    ],
    course_considerations: [
      { title: -> { I18n.t("Blueprint Courses") },
        description: -> { I18n.t("Blueprint courses must be enabled for an account by an admin.") } },
      { description: -> { I18n.t("Course roles can only manage content in Blueprint Courses if they are added to the Blueprint Course as a teacher, TA, or designer role.") } },
      { description: -> { I18n.t("If the Pages - Update permission is disabled, the user can still adjust content lock settings on individual pages in a Blueprint Master Course.") } },
      { title: -> { I18n.t("Student Page History") },
        description: -> { I18n.t("Students can edit and view page history if allowed in the options for an individual page.") } }
    ]
  },
  users_manage_access_tokens: {
    label: -> { I18n.t("Users - Manage Access Tokens") },
    subtitle: -> { I18n.t("create / update / delete / view") },
    account_details: [
      { title: -> { I18n.t("Access Tokens - create / update") },
        description: -> { I18n.t("Allows user to create access tokens on behalf of another user.") } },
      { description: -> { I18n.t("Allows user to update access tokens on behalf of another user.") } },
      { description: -> { I18n.t("Allows user to regenerate access tokens on behalf of another user.") } },
      { description: -> { I18n.t("Allows user to still create access tokens for themself when the Limit Personal Access Token Creation setting is on.") } },
      { description: -> { I18n.t("Allows user to still update their access tokens when the Limit Personal Access Token Creation setting is on.") } },
      { description: -> { I18n.t("Allows user to still regenerate their access tokens when the Limit Personal Access Token Creation setting is on.") } },
      { title: -> { I18n.t("Access Tokens - delete") },
        description: -> { I18n.t("Allows user to delete access tokens on behalf of another user.") } },
      {
        title: -> { I18n.t("Access Tokens - view") },
        description: -> { I18n.t("Allows user to view access tokens on behalf of another user. This does not include viewing the token string, which is only shown at the time of creation.") }
      }
    ]
  },
  manage_temporary_enrollments: {
    label: -> { I18n.t("Users - Temporary Enrollments") },
    subtitle: -> { I18n.t("add / edit / delete") },
    account_details: [
      { title: -> { I18n.t("Manage Temporary Enrollments") },
        description: -> { I18n.t("Temporarily enroll a user into a course. This temporary enrollment is paired up with another enrollment within the course.") } },
      { description: -> { I18n.t("The temporarily enrolled user can only view and participate in a course between the start and end dates that were chosen when making the temporary enrollment.") } },
      { title: -> { I18n.t("Temporary Enrollments - add") },
        description: -> { I18n.t("Allows users to add a temporary enrollment with a start date, end date, and role") } },
      { title: -> { I18n.t("Temporary Enrollments - edit") },
        description: -> { I18n.t("Allows users to edit an existing temporary enrollment") } },
      { title: -> { I18n.t("Temporary Enrollments - delete") },
        description: -> { I18n.t("Allows users to delete a temporary enrollment") } }
    ]
  },
  view_advanced_analytics: {
    label: -> { I18n.t("Intelligent Insights") },
    subtitle: -> { I18n.t("ask your data / students in need / course readiness / financial aid") },
  },
  manage_rate_limiting: {
    label: -> { I18n.t("Site Admin - Rate Limiting") },
    subtitle: -> { I18n.t("add / edit / delete rate limits for external tools") },
    account_details: [
      { title: -> { I18n.t("Rate Limiting - add") },
        description: -> { I18n.t("Allows user to create new rate limit settings for external tools and integrations.") } },
      { title: -> { I18n.t("Rate Limiting - edit") },
        description: -> { I18n.t("Allows user to modify existing rate limit settings, including changing rate limit values and comments.") } },
      { title: -> { I18n.t("Rate Limiting - delete") },
        description: -> { I18n.t("Allows user to remove rate limit settings for external tools and integrations.") } },
      { title: -> { I18n.t("Rate Limiting - view") },
        description: -> { I18n.t("Allows user to view all rate limit settings and their details.") } }
    ],
    account_considerations: [
      { title: -> { I18n.t("Site Admin Only") },
        description: -> { I18n.t("This permission is only available to Site Admin users and requires the api_rate_limits feature flag to be enabled.") } },
      { title: -> { I18n.t("External Tools") },
        description: -> { I18n.t("Rate limiting settings apply to external tools and integrations that use OAuth client configurations with throttling parameters.") } },
      { title: -> { I18n.t("UTID Integration") },
        description: -> { I18n.t("This feature supports UTID (Unified Tool ID) based rate limiting for partner tools and products.") } }
    ]
  }
}.freeze
