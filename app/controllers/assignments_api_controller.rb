#
# Copyright (C) 2011 - present Instructure, Inc.
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

# @API Assignments
#
# API for accessing assignment information.
#
# @model ExternalToolTagAttributes
#     {
#       "id": "ExternalToolTagAttributes",
#       "description": "",
#       "properties": {
#         "url": {
#           "description": "URL to the external tool",
#           "example": "http://instructure.com",
#           "type": "string"
#         },
#         "new_tab": {
#           "description": "Whether or not there is a new tab for the external tool",
#           "example": false,
#           "type": "boolean"
#         },
#         "resource_link_id": {
#           "description": "the identifier for this tool_tag",
#           "example": "ab81173af98b8c33e66a",
#           "type": "string"
#         }
#       }
#     }
#
# @model LockInfo
#     {
#       "id": "LockInfo",
#       "description": "",
#       "properties": {
#         "asset_string": {
#           "description": "Asset string for the object causing the lock",
#           "example": "assignment_4",
#           "type": "string"
#         },
#         "unlock_at": {
#           "description": "(Optional) Time at which this was/will be unlocked. Must be before the due date.",
#           "example": "2013-01-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "(Optional) Time at which this was/will be locked. Must be after the due date.",
#           "example": "2013-02-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "context_module": {
#           "description": "(Optional) Context module causing the lock.",
#           "example": "{}",
#           "type": "string"
#         },
#         "manually_locked": {
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model RubricRating
#     {
#       "id": "RubricRating",
#       "description": "",
#       "properties": {
#         "points": {
#           "example": 10,
#           "type": "integer"
#         },
#         "id": {
#           "example": "rat1",
#           "type": "string"
#         },
#         "description": {
#           "example": "Full marks",
#           "type": "string"
#         },
#        "long_description": {
#           "example": "Student completed the assignment flawlessly.",
#           "type": "string"
#         }
#       }
#     }
#
# @model RubricCriteria
#     {
#       "id": "RubricCriteria",
#       "description": "",
#       "properties": {
#         "points": {
#           "example": 10,
#           "type": "integer"
#         },
#         "id": {
#           "description": "The id of rubric criteria.",
#           "example": "crit1",
#           "type": "string"
#         },
#         "learning_outcome_id": {
#           "description": "(Optional) The id of the learning outcome this criteria uses, if any.",
#           "example": "1234",
#           "type": "string"
#         },
#         "vendor_guid": {
#           "description": "(Optional) The 3rd party vendor's GUID for the outcome this criteria references, if any.",
#           "example": "abdsfjasdfne3jsdfn2",
#           "type": "string"
#         },
#         "description": {
#           "example": "Criterion 1",
#           "type": "string"
#         },
#         "long_description": {
#           "example": "Criterion 1 more details",
#           "type": "string"
#         },
#         "criterion_use_range": {
#           "example": true,
#           "type": "boolean"
#         },
#         "ratings": {
#           "type": "array",
#           "items": { "$ref": "RubricRating" }
#         },
#         "ignore_for_scoring": {
#           "type": "boolean",
#           "example": true
#         }
#       }
#     }
#
# @model AssignmentDate
#     {
#       "id": "AssignmentDate",
#       "description": "Object representing a due date for an assignment or quiz. If the due date came from an assignment override, it will have an 'id' field.",
#       "properties": {
#         "id": {
#           "example": 1,
#           "type": "integer",
#           "description": "(Optional, missing if 'base' is present) id of the assignment override this date represents"
#         },
#         "base": {
#           "example": true,
#           "type": "boolean",
#           "description": "(Optional, present if 'id' is missing) whether this date represents the assignment's or quiz's default due date"
#         },
#         "title": {
#           "example": "Summer Session",
#           "type": "string"
#         },
#         "due_at": {
#          "description": "The due date for the assignment. Must be between the unlock date and the lock date if there are lock dates",
#           "example": "2013-08-28T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "The unlock date for the assignment. Must be before the due date if there is a due date.",
#           "example": "2013-08-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "The lock date for the assignment. Must be after the due date if there is a due date.",
#           "example": "2013-08-31T23:59:00-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
# @model TurnitinSettings
#     {
#       "id": "TurnitinSettings",
#       "description": "",
#       "properties": {
#         "originality_report_visibility": {
#           "example": "after_grading",
#           "type": "string"
#         },
#         "s_paper_check": {
#           "example": false,
#           "type": "boolean"
#         },
#         "internet_check": {
#           "example": false,
#           "type": "boolean"
#         },
#         "journal_check": {
#           "example": false,
#           "type": "boolean"
#         },
#         "exclude_biblio": {
#           "example": false,
#           "type": "boolean"
#         },
#         "exclude_quoted": {
#           "example": false,
#           "type": "boolean"
#         },
#         "exclude_small_matches_type": {
#           "example": "percent",
#           "type": "string"
#         },
#         "exclude_small_matches_value": {
#           "example": 50,
#           "type": "integer"
#         }
#       }
#     }
#
# @model NeedsGradingCount
#     {
#       "id": "NeedsGradingCount",
#       "description": "Used by Assignment model",
#       "properties": {
#         "section_id": {
#           "description": "The section ID",
#           "example": "123456",
#           "type": "string"
#         },
#         "needs_grading_count": {
#           "description": "Number of submissions that need grading",
#           "example": 5,
#           "type": "integer"
#         }
#       }
#     }
#
# @model Assignment
#     {
#       "id": "Assignment",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the assignment",
#           "example": 4,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the assignment",
#           "example": "some assignment",
#           "type": "string"
#         },
#         "description": {
#           "description": "the assignment description, in an HTML fragment",
#           "example": "<p>Do the following:</p>...",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "The time at which this assignment was originally created",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The time at which this assignment was last modified in any way",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "due_at": {
#           "description": "the due date for the assignment. returns null if not present. NOTE: If this assignment has assignment overrides, this field will be the due date as it applies to the user requesting information from the API.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "the lock date (assignment is locked after this date). returns null if not present. NOTE: If this assignment has assignment overrides, this field will be the lock date as it applies to the user requesting information from the API.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "the unlock date (assignment is unlocked after this date) returns null if not present NOTE: If this assignment has assignment overrides, this field will be the unlock date as it applies to the user requesting information from the API.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "has_overrides": {
#           "description": "whether this assignment has overrides",
#           "example": true,
#           "type": "boolean"
#         },
#         "all_dates": {
#           "description": "(Optional) all dates associated with the assignment, if applicable",
#           "type": "array",
#           "items": { "$ref": "AssignmentDate" }
#         },
#         "course_id": {
#           "description": "the ID of the course the assignment belongs to",
#           "example": 123,
#           "type": "integer"
#         },
#         "html_url": {
#           "description": "the URL to the assignment's web page",
#           "example": "https://...",
#           "type": "string"
#         },
#         "submissions_download_url": {
#           "description": "the URL to download all submissions as a zip",
#           "example": "https://example.com/courses/:course_id/assignments/:id/submissions?zip=1",
#           "type": "string"
#         },
#         "assignment_group_id": {
#           "description": "the ID of the assignment's group",
#           "example": 2,
#           "type": "integer"
#         },
#         "due_date_required": {
#           "description": "Boolean flag indicating whether the assignment requires a due date based on the account level setting",
#           "example": true,
#           "type": "boolean"
#         },
#         "allowed_extensions": {
#           "description": "Allowed file extensions, which take effect if submission_types includes 'online_upload'.",
#           "example": ["docx", "ppt"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "max_name_length": {
#           "description": "An integer indicating the maximum length an assignment's name may be",
#           "example": 15,
#           "type": "integer"
#         },
#         "turnitin_enabled": {
#           "description": "Boolean flag indicating whether or not Turnitin has been enabled for the assignment. NOTE: This flag will not appear unless your account has the Turnitin plugin available",
#           "example": true,
#           "type": "boolean"
#         },
#         "vericite_enabled": {
#           "description": "Boolean flag indicating whether or not VeriCite has been enabled for the assignment. NOTE: This flag will not appear unless your account has the VeriCite plugin available",
#           "example": true,
#           "type": "boolean"
#         },
#         "turnitin_settings": {
#           "description": "Settings to pass along to turnitin to control what kinds of matches should be considered. originality_report_visibility can be 'immediate', 'after_grading', 'after_due_date', or 'never' exclude_small_matches_type can be null, 'percent', 'words' exclude_small_matches_value: - if type is null, this will be null also - if type is 'percent', this will be a number between 0 and 100 representing match size to exclude as a percentage of the document size. - if type is 'words', this will be number > 0 representing how many words a match must contain for it to be considered NOTE: This flag will not appear unless your account has the Turnitin plugin available",
#           "$ref": "TurnitinSettings"
#         },
#         "grade_group_students_individually": {
#           "description": "If this is a group assignment, boolean flag indicating whether or not students will be graded individually.",
#           "example": false,
#           "type": "boolean"
#         },
#         "external_tool_tag_attributes": {
#           "description": "(Optional) assignment's settings for external tools if submission_types include 'external_tool'. Only url and new_tab are included (new_tab defaults to false).  Use the 'External Tools' API if you need more information about an external tool.",
#           "$ref": "ExternalToolTagAttributes"
#         },
#         "peer_reviews": {
#           "description": "Boolean indicating if peer reviews are required for this assignment",
#           "example": false,
#           "type": "boolean"
#         },
#         "automatic_peer_reviews": {
#           "description": "Boolean indicating peer reviews are assigned automatically. If false, the teacher is expected to manually assign peer reviews.",
#           "example": false,
#           "type": "boolean"
#         },
#         "peer_review_count": {
#           "description": "Integer representing the amount of reviews each user is assigned. NOTE: This key is NOT present unless you have automatic_peer_reviews set to true.",
#           "example": 0,
#           "type": "integer"
#         },
#         "peer_reviews_assign_at": {
#           "description": "String representing a date the reviews are due by. Must be a date that occurs after the default due date. If blank, or date is not after the assignment's due date, the assignment's due date will be used. NOTE: This key is NOT present unless you have automatic_peer_reviews set to true.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "intra_group_peer_reviews": {
#           "description": "Boolean representing whether or not members from within the same group on a group assignment can be assigned to peer review their own group's work",
#           "example": "false",
#           "type": "boolean"
#         },
#         "group_category_id": {
#           "description": "The ID of the assignment’s group set, if this is a group assignment. For group discussions, set group_category_id on the discussion topic, not the linked assignment.",
#           "example": 1,
#           "type": "integer"
#         },
#         "needs_grading_count": {
#           "description": "if the requesting user has grading rights, the number of submissions that need grading.",
#           "example": 17,
#           "type": "integer"
#         },
#         "needs_grading_count_by_section": {
#           "description": "if the requesting user has grading rights and the 'needs_grading_count_by_section' flag is specified, the number of submissions that need grading split out by section. NOTE: This key is NOT present unless you pass the 'needs_grading_count_by_section' argument as true.  ANOTHER NOTE: it's possible to be enrolled in multiple sections, and if a student is setup that way they will show an assignment that needs grading in multiple sections (effectively the count will be duplicated between sections)",
#           "example": [
#             {"section_id":"123456","needs_grading_count":5},
#             {"section_id":"654321","needs_grading_count":0}
#           ],
#           "type": "array",
#           "items": { "$ref": "NeedsGradingCount" }
#         },
#         "position": {
#           "description": "the sorting order of the assignment in the group",
#           "example": 1,
#           "type": "integer"
#         },
#         "post_to_sis": {
#           "example": true,
#           "type" : "boolean",
#           "description" : "(optional, present if Sync Grades to SIS feature is enabled)"
#         },
#         "integration_id": {
#           "example": "12341234",
#           "type" : "string",
#           "description" : "(optional, Third Party unique identifier for Assignment)"
#         },
#         "integration_data": {
#           "example": {"5678": "0954"},
#           "type" : "object",
#           "description" : "(optional, Third Party integration data for assignment)"
#         },
#         "muted": {
#           "description": "For courses using Old Gradebook, indicates whether the assignment is muted. For courses using New Gradebook, true if the assignment has any unposted submissions, otherwise false. To see the posted status of submissions, check the 'posted_attribute' on Submission.",
#           "type": "boolean"
#         },
#         "points_possible": {
#           "description": "the maximum points possible for the assignment",
#           "example": 12.0,
#           "type": "number"
#         },
#         "submission_types": {
#           "description": "the types of submissions allowed for this assignment list containing one or more of the following: 'discussion_topic', 'online_quiz', 'on_paper', 'none', 'external_tool', 'online_text_entry', 'online_url', 'online_upload' 'media_recording'",
#           "example": ["online_text_entry"],
#           "type": "array",
#           "items": {"type": "string"},
#           "allowableValues": {
#             "values": [
#               "discussion_topic",
#               "online_quiz",
#               "on_paper",
#               "not_graded",
#               "none",
#               "external_tool",
#               "online_text_entry",
#               "online_url",
#               "online_upload",
#               "media_recording"
#             ]
#           }
#         },
#         "has_submitted_submissions": {
#           "description": "If true, the assignment has been submitted to by at least one student",
#           "example": true,
#           "type": "boolean"
#         },
#         "grading_type": {
#           "description": "The type of grading the assignment receives; one of 'pass_fail', 'percent', 'letter_grade', 'gpa_scale', 'points'",
#           "example": "points",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "pass_fail",
#               "percent",
#               "letter_grade",
#               "gpa_scale",
#               "points"
#             ]
#           }
#         },
#         "grading_standard_id": {
#           "description": "The id of the grading standard being applied to this assignment. Valid if grading_type is 'letter_grade' or 'gpa_scale'.",
#           "type": "integer"
#         },
#         "published": {
#           "description": "Whether the assignment is published",
#           "example": true,
#           "type": "boolean"
#         },
#         "unpublishable": {
#           "description": "Whether the assignment's 'published' state can be changed to false. Will be false if there are student submissions for the assignment.",
#           "example": false,
#           "type": "boolean"
#         },
#         "only_visible_to_overrides": {
#           "description": "Whether the assignment is only visible to overrides.",
#           "example": false,
#           "type": "boolean"
#         },
#         "locked_for_user": {
#           "description": "Whether or not this is locked for the user.",
#           "example": false,
#           "type": "boolean"
#         },
#         "lock_info": {
#           "description": "(Optional) Information for the user about the lock. Present when locked_for_user is true.",
#           "$ref": "LockInfo"
#         },
#         "lock_explanation": {
#           "description": "(Optional) An explanation of why this is locked for the user. Present when locked_for_user is true.",
#           "example": "This assignment is locked until September 1 at 12:00am",
#           "type": "string"
#         },
#         "quiz_id": {
#           "description": "(Optional) id of the associated quiz (applies only when submission_types is ['online_quiz'])",
#           "example": 620,
#           "type": "integer"
#         },
#         "anonymous_submissions": {
#           "description": "(Optional) whether anonymous submissions are accepted (applies only to quiz assignments)",
#           "example": false,
#           "type": "boolean"
#         },
#         "discussion_topic": {
#           "description": "(Optional) the DiscussionTopic associated with the assignment, if applicable",
#           "$ref": "DiscussionTopic"
#         },
#         "freeze_on_copy": {
#           "description": "(Optional) Boolean indicating if assignment will be frozen when it is copied. NOTE: This field will only be present if the AssignmentFreezer plugin is available for your account.",
#           "example": false,
#           "type": "boolean"
#         },
#         "frozen": {
#           "description": "(Optional) Boolean indicating if assignment is frozen for the calling user. NOTE: This field will only be present if the AssignmentFreezer plugin is available for your account.",
#           "example": false,
#           "type": "boolean"
#         },
#         "frozen_attributes": {
#           "description": "(Optional) Array of frozen attributes for the assignment. Only account administrators currently have permission to change an attribute in this list. Will be empty if no attributes are frozen for this assignment. Possible frozen attributes are: title, description, lock_at, points_possible, grading_type, submission_types, assignment_group_id, allowed_extensions, group_category_id, notify_of_update, peer_reviews NOTE: This field will only be present if the AssignmentFreezer plugin is available for your account.",
#           "example": ["title"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "submission": {
#           "description": "(Optional) If 'submission' is included in the 'include' parameter, includes a Submission object that represents the current user's (user who is requesting information from the api) current submission for the assignment. See the Submissions API for an example response. If the user does not have a submission, this key will be absent.",
#           "$ref": "Submission"
#         },
#         "use_rubric_for_grading": {
#           "description": "(Optional) If true, the rubric is directly tied to grading the assignment. Otherwise, it is only advisory. Included if there is an associated rubric.",
#           "example": true,
#           "type": "boolean"
#         },
#         "rubric_settings": {
#           "description": "(Optional) An object describing the basic attributes of the rubric, including the point total. Included if there is an associated rubric.",
#           "example": "{\"points_possible\"=>12}",
#           "type": "string"
#         },
#         "rubric": {
#           "description": "(Optional) A list of scoring criteria and ratings for each rubric criterion. Included if there is an associated rubric.",
#           "type": "array",
#           "items": { "$ref": "RubricCriteria" }
#         },
#         "assignment_visibility": {
#           "description": "(Optional) If 'assignment_visibility' is included in the 'include' parameter, includes an array of student IDs who can see this assignment.",
#           "example": [137,381,572],
#           "type": "array",
#           "items": {"type": "integer"}
#         },
#         "overrides": {
#           "description": "(Optional) If 'overrides' is included in the 'include' parameter, includes an array of assignment override objects.",
#           "type": "array",
#           "items": { "$ref": "AssignmentOverride" }
#         },
#         "omit_from_final_grade": {
#           "description": "(Optional) If true, the assignment will be omitted from the student's final grade",
#           "example": true,
#           "type": "boolean"
#         },
#         "moderated_grading": {
#           "description": "Boolean indicating if the assignment is moderated.",
#           "example": true,
#           "type": "boolean"
#         },
#         "grader_count": {
#           "description": "The maximum number of provisional graders who may issue grades for this assignment. Only relevant for moderated assignments. Must be a positive value, and must be set to 1 if the course has fewer than two active instructors. Otherwise, the maximum value is the number of active instructors in the course minus one, or 10 if the course has more than 11 active instructors.",
#           "example": 3,
#           "type": "integer"
#         },
#         "final_grader_id": {
#           "description": "The user ID of the grader responsible for choosing final grades for this assignment. Only relevant for moderated assignments.",
#           "example": 3,
#           "type": "integer"
#         },
#         "grader_comments_visible_to_graders": {
#           "description": "Boolean indicating if provisional graders' comments are visible to other provisional graders. Only relevant for moderated assignments.",
#           "example": true,
#           "type": "boolean"
#         },
#         "graders_anonymous_to_graders": {
#           "description": "Boolean indicating if provisional graders' identities are hidden from other provisional graders. Only relevant for moderated assignments with grader_comments_visible_to_graders set to true.",
#           "example": true,
#           "type": "boolean"
#         },
#         "grader_names_visible_to_final_grader": {
#           "description": "Boolean indicating if provisional grader identities are visible to the final grader. Only relevant for moderated assignments.",
#           "example": true,
#           "type": "boolean"
#         },
#         "anonymous_grading": {
#           "description": "Boolean indicating if the assignment is graded anonymously. If true, graders cannot see student identities.",
#           "example": true,
#           "type": "boolean"
#         },
#         "allowed_attempts": {
#           "description": "The number of submission attempts a student can make for this assignment. -1 is considered unlimited.",
#           "example": 2,
#           "type": "integer"
#         },
#         "post_manually": {
#           "description": "Whether the assignment has manual posting enabled. Only relevant for courses using New Gradebook.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
class AssignmentsApiController < ApplicationController
  before_action :require_context
  before_action :require_user_visibility, :only=>[:user_index]
  include Api::V1::Assignment
  include Api::V1::Submission
  include Api::V1::AssignmentOverride
  include Api::V1::Quiz

  # @API List assignments
  # Returns the paginated list of assignments for the current course or assignment group.
  # @argument include[] [String, "submission"|"assignment_visibility"|"all_dates"|"overrides"|"observed_users"]
  #   Associations to include with the assignment. The "assignment_visibility" option
  #   requires that the Differentiated Assignments course feature be turned on. If
  #   "observed_users" is passed, submissions for observed users will also be included as an array.
  # @argument search_term [String]
  #   The partial title of the assignments to match and return.
  # @argument override_assignment_dates [Boolean]
  #   Apply assignment overrides for each assignment, defaults to true.
  # @argument needs_grading_count_by_section [Boolean]
  #   Split up "needs_grading_count" by sections into the "needs_grading_count_by_section" key, defaults to false
  # @argument bucket [String, "past"|"overdue"|"undated"|"ungraded"|"unsubmitted"|"upcoming"|"future"]
  #   If included, only return certain assignments depending on due date and submission status.
  # @argument assignment_ids[] if set, return only assignments specified
  # @argument order_by [String, "position"|"name"|"due_at"]
  #   Determines the order of the assignments. Defaults to "position".
  # @argument post_to_sis [Boolean]
  #   Return only assignments that have post_to_sis set or not set.
  # @returns [Assignment]
  def index
    error_or_array= get_assignments(@current_user)
    render :json => error_or_array unless performed?
  end

  # @API List assignments for user
  # Returns the paginated list of assignments for the specified user if the current user has rights to view.
  # See {api:AssignmentsApiController#index List assignments} for valid arguments.
  def user_index
    @user.shard.activate do
      error_or_array= get_assignments(@user)
      render :json => error_or_array unless performed?
    end
  end

  def duplicate
    # see private methods for definitions
    old_assignment = old_assignment_for_duplicate
    target_assignment = target_assignment_for_duplicate
    target_course = target_course_for_duplicate

    if !old_assignment || old_assignment.workflow_state == "deleted"
      return render json: { error: t('assignment does not exist') }, status: :bad_request
    end

    if old_assignment.quiz
      return render json: { error: t('quiz duplication not implemented') }, status: :bad_request
    end

    return unless authorized_action(old_assignment, @current_user, :create)

    new_assignment = old_assignment.duplicate(
      user: @current_user,
      # in case of failure retry, just reuse the title of failed assignment
      # otherwise, we will have "assignment copy copy..." with multiple retries
      copy_title: failure_retry? ? target_assignment.title : nil,
      target_context: course_copy_retry? ? target_course : nil
    )

    # if duplicated assignment is expected to be in a different course (course copy)
    # set context and assignment_group
    if course_copy_retry?
      new_assignment.context = target_course
      new_assignment.assignment_group = target_assignment.assignment_group
    end

    new_assignment.insert_at(target_assignment.position + 1)
    new_assignment.save!
    positions_in_group = Assignment.active.where(
      assignment_group_id: target_assignment.assignment_group_id
    ).pluck("id", "position")
    positions_hash = {}
    positions_in_group.each do |id_pos_pair|
      positions_hash[id_pos_pair[0]] = id_pos_pair[1]
    end

    if new_assignment
      assignment_topic = target_assignment.discussion_topic
      if assignment_topic&.pinned && !assignment_topic&.position.nil?
        new_assignment.discussion_topic.insert_at(assignment_topic.position + 1)
      end
      # return assignment json based on requested result type
      # Serializing an assignment into a quiz format is required by N.Q Quiz shells on Quizzes Page
      result_json = if use_quiz_json?
        quiz_json(new_assignment, @context, @current_user, session, {}, QuizzesNext::QuizSerializer)
      else
        # Include the updated positions in the response so the frontend can
        # update them appropriately
        assignment_json(new_assignment, @current_user, session)
      end

      result_json['new_positions'] = positions_hash
      render :json => result_json
    else
      render json: { error: t('cannot save new assignment') }, status: :bad_request
    end
  end

  def get_assignments(user)
    if authorized_action(@context, user, :read)
      log_api_asset_access([ "assignments", @context ], "assignments", "other")
      scope = Assignments::ScopedToUser.new(@context, user).scope.
        eager_load(:assignment_group).
        preload(:rubric_association, :rubric).
        reorder("assignment_groups.position, assignments.position, assignments.id")
      scope = Assignment.search_by_attribute(scope, :title, params[:search_term])
      include_params = Array(params[:include])

      if params[:bucket]
        return invalid_bucket_error unless SortsAssignments::VALID_BUCKETS.include?(params[:bucket].to_sym)

        users = current_user_and_observed(
                    include_observed: include_params.include?("observed_users"))
        submissions_for_user = scope.with_submissions_for_user(users).flat_map(&:submissions)
        scope = SortsAssignments.bucket_filter(scope, params[:bucket], session, user, @current_user, @context, submissions_for_user)
      end

      scope = scope.where(post_to_sis: value_to_boolean(params[:post_to_sis])) if params[:post_to_sis] && authorized_action(@context, user, :manage_assignments)

      if params[:assignment_ids]
        if params[:assignment_ids].length > Api.max_per_page
          return render json: { message: "Request contains too many assignment_ids.  Limit #{Api.max_per_page}" }, status: 400
        end
        scope = scope.where(id: params[:assignment_ids])
      end
      case params[:order_by]
      when 'name'
        scope = scope.reorder(Arel.sql("#{Assignment.best_unicode_collation_key('assignments.title')}, assignment_groups.position, assignments.position, assignments.id"))
      when 'due_at'
        if @context.grants_right?(user, :read_as_admin)
          scope = scope.with_latest_due_date.reorder(Arel.sql("latest_due_date, #{Assignment.best_unicode_collation_key('assignments.title')}, assignment_groups.position, assignments.position, assignments.id"))
        else
          scope = scope.with_user_due_date(user).reorder(Arel.sql("user_due_date, #{Assignment.best_unicode_collation_key('assignments.title')}, assignment_groups.position, assignments.position, assignments.id"))
        end
      end

      assignments = if params[:assignment_group_id].present?
        assignment_group_id = params[:assignment_group_id]
        scope = scope.where(assignment_group_id: assignment_group_id)
        Api.paginate(scope, self, api_v1_course_assignment_group_assignments_url(@context, assignment_group_id))
      else
        Api.paginate(scope, self, api_v1_course_assignments_url(@context))
      end

      if params[:assignment_ids] && assignments.length != params[:assignment_ids].length
        invalid_ids = params[:assignment_ids] - assignments.map(&:id).map(&:to_s)
        return render json: { message: "Invalid assignment_ids: #{invalid_ids.join(',')}" }, status: 400
      end

      submissions = submissions_hash(include_params, assignments, submissions_for_user)

      include_all_dates = include_params.include?('all_dates')
      include_override_objects = include_params.include?('overrides') && @context.grants_any_right?(user, :manage_assignments)

      override_param = params[:override_assignment_dates] || true
      override_dates = value_to_boolean(override_param)
      if override_dates || include_all_dates || include_override_objects
        ActiveRecord::Associations::Preloader.new.preload(assignments, :assignment_overrides)
        assignments.select{ |a| a.assignment_overrides.size == 0 }.
          each { |a| a.has_no_overrides = true }

        if AssignmentOverrideApplicator.should_preload_override_students?(assignments, user, "assignments_api")
          AssignmentOverrideApplicator.preload_assignment_override_students(assignments, user)
        end
      end

      include_visibility = include_params.include?('assignment_visibility') && @context.grants_any_right?(user, :read_as_admin, :manage_grades, :manage_assignments)

      if include_visibility
        assignment_visibilities = AssignmentStudentVisibility.users_with_visibility_by_assignment(course_id: @context.id, assignment_id: assignments.map(&:id))
      end

      needs_grading_by_section_param = params[:needs_grading_count_by_section] || false
      needs_grading_count_by_section = value_to_boolean(needs_grading_by_section_param)

      if @context.grants_right?(user, :manage_assignments)
        Assignment.preload_can_unpublish(assignments)
      end

      unless @context.grants_right?(user, :read_as_admin)
        Assignment.preload_context_module_tags(assignments) # running this again is fine
      end

      preloaded_attachments = api_bulk_load_user_content_attachments(assignments.map(&:description), @context)

      hashes = []
      hashes = assignments.map do |assignment|

        visibility_array = assignment_visibilities[assignment.id] if assignment_visibilities
        submission = submissions[assignment.id]
        needs_grading_course_proxy = @context.grants_right?(user, session, :manage_grades) ?
          Assignments::NeedsGradingCountQuery::CourseProxy.new(@context, user) : nil

        assignment_json(assignment, user, session,
                        submission: submission, override_dates: override_dates,
                        include_visibility: include_visibility,
                        assignment_visibilities: visibility_array,
                        needs_grading_count_by_section: needs_grading_count_by_section,
                        needs_grading_course_proxy: needs_grading_course_proxy,
                        include_all_dates: include_all_dates,
                        bucket: params[:bucket],
                        include_overrides: include_override_objects,
                        preloaded_user_content_attachments: preloaded_attachments
                        )
      end
      hashes
    end
  end

  # @API Get a single assignment
  # Returns the assignment with the given id.
  # @argument include[] [String, "submission"|"assignment_visibility"|"overrides"|"observed_users"]
  #   Associations to include with the assignment. The "assignment_visibility" option
  #   requires that the Differentiated Assignments course feature be turned on. If
  #   "observed_users" is passed, submissions for observed users will also be included.
  # @argument override_assignment_dates [Boolean]
  #   Apply assignment overrides to the assignment, defaults to true.
  # @argument needs_grading_count_by_section [Boolean]
  #   Split up "needs_grading_count" by sections into the "needs_grading_count_by_section" key, defaults to false
  # @argument all_dates [Boolean]
  #   All dates associated with the assignment, if applicable
  # @returns Assignment
  def show
    @assignment = api_find(@context.active_assignments.preload(:assignment_group, :rubric_association, :rubric), params[:id])
    if authorized_action(@assignment, @current_user, :read)
      return render_unauthorized_action unless @assignment.visible_to_user?(@current_user)

      included_params = Array(params[:include])
      if included_params.include?('submission')
        submissions =
          submissions_hash(included_params, [@assignment])[@assignment.id]
      end

      include_visibility = included_params.include?('assignment_visibility') && @context.grants_any_right?(@current_user, :read_as_admin, :manage_grades, :manage_assignments)
      include_all_dates = value_to_boolean(params[:all_dates] || false)

      include_override_objects = included_params.include?('overrides') && @context.grants_any_right?(@current_user, :manage_assignments)

      override_param = params[:override_assignment_dates] || true
      override_dates = value_to_boolean(override_param)

      needs_grading_by_section_param = params[:needs_grading_count_by_section] || false
      needs_grading_count_by_section = value_to_boolean(needs_grading_by_section_param)

      locked = @assignment.locked_for?(@current_user, :check_policies => true)
      @assignment.context_module_action(@current_user, :read) unless locked && !locked[:can_view]
      log_api_asset_access(@assignment, "assignments", @assignment.assignment_group)

      options = {
        submission: submissions,
        override_dates: override_dates,
        include_visibility: include_visibility,
        needs_grading_count_by_section: needs_grading_count_by_section,
        include_all_dates: include_all_dates,
        include_overrides: include_override_objects
      }

      result_json = if use_quiz_json?
        quiz_json(@assignment, @context, @current_user, session, {}, QuizzesNext::QuizSerializer)
      else
        assignment_json(@assignment, @current_user, session, options)
      end

      render :json => result_json
    end
  end

  # @API Create an assignment
  # Create a new assignment for this course. The assignment is created in the
  # active state.
  #
  # @argument assignment[name] [Required, String] The assignment name.
  #
  # @argument assignment[position] [Integer]
  #   The position of this assignment in the group when displaying
  #   assignment lists.
  #
  # @argument assignment[submission_types][] [String, "online_quiz"|"none"|"on_paper"|"discussion_topic"|"external_tool"|"online_upload"|"online_text_entry"|"online_url"|"media_recording"]
  #   List of supported submission types for the assignment.
  #   Unless the assignment is allowing online submissions, the array should
  #   only have one element.
  #
  #   If not allowing online submissions, your options are:
  #     "online_quiz"
  #     "none"
  #     "on_paper"
  #     "discussion_topic"
  #     "external_tool"
  #
  #   If you are allowing online submissions, you can have one or many
  #   allowed submission types:
  #
  #     "online_upload"
  #     "online_text_entry"
  #     "online_url"
  #     "media_recording" (Only valid when the Kaltura plugin is enabled)
  #
  # @argument assignment[allowed_extensions][] [String]
  #   Allowed extensions if submission_types includes "online_upload"
  #
  #   Example:
  #     allowed_extensions: ["docx","ppt"]
  #
  # @argument assignment[turnitin_enabled] [Boolean]
  #   Only applies when the Turnitin plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles Turnitin submissions for the assignment.
  #   Will be ignored if Turnitin is not available for the course.
  #
  # @argument assignment[vericite_enabled] [Boolean]
  #   Only applies when the VeriCite plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles VeriCite submissions for the assignment.
  #   Will be ignored if VeriCite is not available for the course.
  #
  # @argument assignment[turnitin_settings]
  #   Settings to send along to turnitin. See Assignment object definition for
  #   format.
  #
  # @argument assignment[integration_data]
  #   Data used for SIS integrations. Requires admin-level token with the "Manage SIS" permission. JSON string required.
  #
  # @argument assignment[integration_id]
  #   Unique ID from third party integrations
  #
  # @argument assignment[peer_reviews] [Boolean]
  #   If submission_types does not include external_tool,discussion_topic,
  #   online_quiz, or on_paper, determines whether or not peer reviews
  #   will be turned on for the assignment.
  #
  # @argument assignment[automatic_peer_reviews] [Boolean]
  #   Whether peer reviews will be assigned automatically by Canvas or if
  #   teachers must manually assign peer reviews. Does not apply if peer reviews
  #   are not enabled.
  #
  # @argument assignment[notify_of_update] [Boolean]
  #   If true, Canvas will send a notification to students in the class
  #   notifying them that the content has changed.
  #
  # @argument assignment[group_category_id] [Integer]
  #   If present, the assignment will become a group assignment assigned
  #   to the group.
  #
  # @argument assignment[grade_group_students_individually] [Integer]
  #   If this is a group assignment, teachers have the options to grade
  #   students individually. If false, Canvas will apply the assignment's
  #   score to each member of the group. If true, the teacher can manually
  #   assign scores to each member of the group.
  #
  # @argument assignment[external_tool_tag_attributes]
  #   Hash of external tool parameters if submission_types is ["external_tool"].
  #   See Assignment object definition for format.
  #
  # @argument assignment[points_possible] [Float]
  #   The maximum points possible on the assignment.
  #
  # @argument assignment[grading_type] ["pass_fail"|"percent"|"letter_grade"|"gpa_scale"|"points"]
  #  The strategy used for grading the assignment.
  #  The assignment defaults to "points" if this field is omitted.
  #
  # @argument assignment[due_at] [DateTime]
  #   The day/time the assignment is due. Must be between the lock dates if there are lock dates.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[lock_at] [DateTime]
  #   The day/time the assignment is locked after. Must be after the due date if there is a due date.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[unlock_at] [DateTime]
  #   The day/time the assignment is unlocked. Must be before the due date if there is a due date.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[description] [String]
  #   The assignment's description, supports HTML.
  #
  # @argument assignment[assignment_group_id] [Integer]
  #   The assignment group id to put the assignment in.
  #   Defaults to the top assignment group in the course.
  #
  # @deprecated_argument assignment[muted] [Boolean] NOTICE 2019-07-13 EFFECTIVE 2020-01-18
  #   Whether this assignment is muted.
  #   A muted assignment does not send change notifications
  #   and hides grades from students.
  #   Defaults to false.
  #   May only be set if the course is using Old Gradebook.
  #
  # @argument assignment[assignment_overrides][] [AssignmentOverride]
  #   List of overrides for the assignment.
  #
  # @argument assignment[only_visible_to_overrides] [Boolean]
  #   Whether this assignment is only visible to overrides
  #   (Only useful if 'differentiated assignments' account setting is on)
  #
  # @argument assignment[published] [Boolean]
  #   Whether this assignment is published.
  #   (Only useful if 'draft state' account setting is on)
  #   Unpublished assignments are not visible to students.
  #
  # @argument assignment[grading_standard_id] [Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
  #   This will update the grading_type for the course to 'letter_grade' unless it is already 'gpa_scale'.
  #
  # @argument assignment[omit_from_final_grade] [Boolean]
  #   Whether this assignment is counted towards a student's final grade.
  #
  # @argument assignment[quiz_lti] [Boolean]
  #   Whether this assignment should use the Quizzes 2 LTI tool. Sets the
  #   submission type to 'external_tool' and configures the external tool
  #   attributes to use the Quizzes 2 LTI tool configured for this course.
  #   Has no effect if no Quizzes 2 LTI tool is configured.
  #
  # @argument assignment[moderated_grading] [Boolean]
  #   Whether this assignment is moderated.
  #
  # @argument assignment[grader_count] [Integer]
  #  The maximum number of provisional graders who may issue grades for this
  #  assignment. Only relevant for moderated assignments. Must be a positive
  #  value, and must be set to 1 if the course has fewer than two active
  #  instructors. Otherwise, the maximum value is the number of active
  #  instructors in the course minus one, or 10 if the course has more than 11
  #  active instructors.
  #
  # @argument assignment[final_grader_id] [Integer]
  #  The user ID of the grader responsible for choosing final grades for this
  #  assignment. Only relevant for moderated assignments.
  #
  # @argument assignment[grader_comments_visible_to_graders] [Boolean]
  #  Boolean indicating if provisional graders' comments are visible to other
  #  provisional graders. Only relevant for moderated assignments.
  #
  # @argument assignment[graders_anonymous_to_graders] [Boolean]
  #  Boolean indicating if provisional graders' identities are hidden from
  #  other provisional graders. Only relevant for moderated assignments.
  #
  # @argument assignment[graders_names_visible_to_final_grader] [Boolean]
  #  Boolean indicating if provisional grader identities are visible to the
  #  the final grader. Only relevant for moderated assignments.
  #
  # @argument assignment[anonymous_grading] [Boolean]
  #  Boolean indicating if the assignment is graded anonymously. If true,
  #  graders cannot see student identities.
  #
  # @argument assignment[allowed_attempts] [Integer]
  #   The number of submission attempts allowed for this assignment. Set to -1 for unlimited attempts.
  #
  # @returns Assignment
  def create
    @assignment = @context.assignments.build
    @assignment.workflow_state = 'unpublished'
    if authorized_action(@assignment, @current_user, :create)
      @assignment.content_being_saved_by(@current_user)
      result = create_api_assignment(@assignment, params.require(:assignment), @current_user, @context,
        calculate_grades: params.delete(:calculate_grades))
      render_create_or_update_result(result)
    end
  end

  # @API Edit an assignment
  # Modify an existing assignment.
  #
  # @argument assignment[name] [String] The assignment name.
  #
  # @argument assignment[position] [Integer]
  #   The position of this assignment in the group when displaying
  #   assignment lists.
  #
  # @argument assignment[submission_types][] [String, "online_quiz"|"none"|"on_paper"|"discussion_topic"|"external_tool"|"online_upload"|"online_text_entry"|"online_url"|"media_recording"]
  #   List of supported submission types for the assignment.
  #   Unless the assignment is allowing online submissions, the array should
  #   only have one element.
  #
  #   If not allowing online submissions, your options are:
  #     "online_quiz"
  #     "none"
  #     "on_paper"
  #     "discussion_topic"
  #     "external_tool"
  #
  #   If you are allowing online submissions, you can have one or many
  #   allowed submission types:
  #
  #     "online_upload"
  #     "online_text_entry"
  #     "online_url"
  #     "media_recording" (Only valid when the Kaltura plugin is enabled)
  #
  # @argument assignment[allowed_extensions][] [String]
  #   Allowed extensions if submission_types includes "online_upload"
  #
  #   Example:
  #     allowed_extensions: ["docx","ppt"]
  #
  # @argument assignment[turnitin_enabled] [Boolean]
  #   Only applies when the Turnitin plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles Turnitin submissions for the assignment.
  #   Will be ignored if Turnitin is not available for the course.
  #
  # @argument assignment[vericite_enabled] [Boolean]
  #   Only applies when the VeriCite plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles VeriCite submissions for the assignment.
  #   Will be ignored if VeriCite is not available for the course.
  #
  # @argument assignment[turnitin_settings]
  #   Settings to send along to turnitin. See Assignment object definition for
  #   format.
  #
  # @argument assignment[sis_assignment_id]
  #   The sis id of the Assignment
  #
  # @argument assignment[integration_data]
  #   Data used for SIS integrations. Requires admin-level token with the "Manage SIS" permission. JSON string required.
  #
  # @argument assignment[integration_id]
  #   Unique ID from third party integrations
  #
  # @argument assignment[peer_reviews] [Boolean]
  #   If submission_types does not include external_tool,discussion_topic,
  #   online_quiz, or on_paper, determines whether or not peer reviews
  #   will be turned on for the assignment.
  #
  # @argument assignment[automatic_peer_reviews] [Boolean]
  #   Whether peer reviews will be assigned automatically by Canvas or if
  #   teachers must manually assign peer reviews. Does not apply if peer reviews
  #   are not enabled.
  #
  # @argument assignment[notify_of_update] [Boolean]
  #   If true, Canvas will send a notification to students in the class
  #   notifying them that the content has changed.
  #
  # @argument assignment[group_category_id] [Integer]
  #   If present, the assignment will become a group assignment assigned
  #   to the group.
  #
  # @argument assignment[grade_group_students_individually] [Integer]
  #   If this is a group assignment, teachers have the options to grade
  #   students individually. If false, Canvas will apply the assignment's
  #   score to each member of the group. If true, the teacher can manually
  #   assign scores to each member of the group.
  #
  # @argument assignment[external_tool_tag_attributes]
  #   Hash of external tool parameters if submission_types is ["external_tool"].
  #   See Assignment object definition for format.
  #
  # @argument assignment[points_possible] [Float]
  #   The maximum points possible on the assignment.
  #
  # @argument assignment[grading_type] ["pass_fail"|"percent"|"letter_grade"|"gpa_scale"|"points"]
  #  The strategy used for grading the assignment.
  #  The assignment defaults to "points" if this field is omitted.
  #
  # @argument assignment[due_at] [DateTime]
  #   The day/time the assignment is due.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[lock_at] [DateTime]
  #   The day/time the assignment is locked after. Must be after the due date if there is a due date.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[unlock_at] [DateTime]
  #   The day/time the assignment is unlocked. Must be before the due date if there is a due date.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[description] [String]
  #   The assignment's description, supports HTML.
  #
  # @argument assignment[assignment_group_id] [Integer]
  #   The assignment group id to put the assignment in.
  #   Defaults to the top assignment group in the course.
  #
  # @deprecated_argument assignment[muted] [Boolean] NOTICE 2019-07-13 EFFECTIVE 2020-01-18
  #   Whether this assignment is muted.
  #   A muted assignment does not send change notifications
  #   and hides grades from students.
  #   Defaults to false.
  #   May only be set if the course is using Old Gradebook.
  #
  # @argument assignment[assignment_overrides][] [AssignmentOverride]
  #   List of overrides for the assignment.
  #
  # @argument assignment[only_visible_to_overrides] [Boolean]
  #   Whether this assignment is only visible to overrides
  #   (Only useful if 'differentiated assignments' account setting is on)
  #
  # @argument assignment[published] [Boolean]
  #   Whether this assignment is published.
  #   (Only useful if 'draft state' account setting is on)
  #   Unpublished assignments are not visible to students.
  #
  # @argument assignment[grading_standard_id] [Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
  #   This will update the grading_type for the course to 'letter_grade' unless it is already 'gpa_scale'.
  #
  # If the assignment [assignment_overrides] key is absent, any existing
  # overrides are kept as is. If the assignment [assignment_overrides] key is
  # present, existing overrides are updated or deleted (and new ones created,
  # as necessary) to match the provided list.
  #
  # @argument assignment[omit_from_final_grade] [Boolean]
  #   Whether this assignment is counted towards a student's final grade.
  #
  # @argument assignment[moderated_grading] [Boolean]
  #   Whether this assignment is moderated.
  #
  # @argument assignment[grader_count] [Integer]
  #  The maximum number of provisional graders who may issue grades for this
  #  assignment. Only relevant for moderated assignments. Must be a positive
  #  value, and must be set to 1 if the course has fewer than two active
  #  instructors. Otherwise, the maximum value is the number of active
  #  instructors in the course minus one, or 10 if the course has more than 11
  #  active instructors.
  #
  # @argument assignment[final_grader_id] [Integer]
  #  The user ID of the grader responsible for choosing final grades for this
  #  assignment. Only relevant for moderated assignments.
  #
  # @argument assignment[grader_comments_visible_to_graders] [Boolean]
  #  Boolean indicating if provisional graders' comments are visible to other
  #  provisional graders. Only relevant for moderated assignments.
  #
  # @argument assignment[graders_anonymous_to_graders] [Boolean]
  #  Boolean indicating if provisional graders' identities are hidden from
  #  other provisional graders. Only relevant for moderated assignments.
  #
  # @argument assignment[graders_names_visible_to_final_grader] [Boolean]
  #  Boolean indicating if provisional grader identities are visible to the
  #  the final grader. Only relevant for moderated assignments.
  #
  # @argument assignment[anonymous_grading] [Boolean]
  #  Boolean indicating if the assignment is graded anonymously. If true,
  #  graders cannot see student identities.
  #
  # @argument assignment[allowed_attempts] [Integer]
  #   The number of submission attempts allowed for this assignment. Set to -1 or null for
  #   unlimited attempts.
  #
  # @returns Assignment
  def update
    @assignment = api_find(@context.active_assignments, params[:id])
    if authorized_action(@assignment, @current_user, :update)
      @assignment.content_being_saved_by(@current_user)
      @assignment.updating_user = @current_user
      # update_api_assignment mutates params so this has to be done here
      opts = assignment_json_opts
      result = update_api_assignment(@assignment, params.require(:assignment), @current_user, @context)
      render_create_or_update_result(result, opts)
    end
  end

  private

  def assignment_json_opts
    return {} unless params[:assignment]&.key?(:override_dates)
    {
      override_dates: value_to_boolean(params[:assignment][:override_dates])
    }
  end

  def render_create_or_update_result(result, opts = {})
    if [:created, :ok].include?(result)
      render json: assignment_json(@assignment, @current_user, session, opts), status: result
    else
      status = result == :forbidden ? :forbidden : :bad_request
      errors = @assignment.errors.as_json[:errors]
      errors['published'] = errors.delete(:workflow_state) if errors.key?(:workflow_state)
      render json: {errors: errors}, status: status
    end
  end

  def invalid_bucket_error
    err_msg = t("bucket name must be one of the following: %{bucket_names}", bucket_names: SortsAssignments::VALID_BUCKETS.join(", "))
    @context.errors.add('bucket', err_msg, :att_name => 'bucket')
    return render :json => @context.errors, :status => :bad_request
  end

  def require_user_visibility
    return render_unauthorized_action unless @current_user.present?
    @user = params[:user_id]=="self" ? @current_user : api_find(User, params[:user_id])
    if @context.grants_right?(@current_user, :view_all_grades)
      # teacher, ta
      return if @context.students_visible_to(@current_user).include?(@user)
    end
    # self, observer
    authorized_action(@user, @current_user, %i(read_as_parent read))
  end

  # old_assignment is the assignement we want to copy from
  def old_assignment_for_duplicate
    @_old_assignment_for_duplicate ||= begin
      assignment_id = params[:assignment_id]
      @context.active_assignments.find_by(id: assignment_id)
    end
  end

  # target assignment is:
  #   - used to postion newly created assignments
  #   - an assignment(failed to duplicate) in target course (course/assignment copy)
  #   - different from old_assignment, in case of "Retry" in course/assignment copy
  #   - same as old_assignment for the initial try of duplicating
  # in a failure retry, we place a new assignment next to the failed assignments
  # in an initial dup request, a new assignment will be placed next to old_assignment
  def target_assignment_for_duplicate
    @_target_assignment_for_duplicate ||= begin
      target_assignment_id = params[:target_assignment_id]
      return old_assignment_for_duplicate if target_assignment_id.blank?
      target_course_for_duplicate.active_assignments.find_by(id: target_assignment_id)
    end
  end

  # target course is:
  #   - the course in which an assignment is duplicated
  #   - different from @context, in case of "Retry" in course copy
  #   - the same @course for assignment copy
  def target_course_for_duplicate
    @_target_course_for_duplicate ||= begin
      target_course_id = params[:target_course_id]
      return @context if target_course_id.blank?
      Course.find_by(id: target_course_id)
    end
  end

  def failure_retry?
    target_assignment_for_duplicate != old_assignment_for_duplicate
  end

  def course_copy_retry?
    target_course_for_duplicate != @context
  end

  def use_quiz_json?
    params[:result_type] == 'Quiz' && @context.root_account.feature_enabled?(:newquizzes_on_quiz_page)
  end
end
