#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
#           "description": "(Optional) Time at which this was/will be unlocked.",
#           "example": "2013-01-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "(Optional) Time at which this was/will be locked.",
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
#           "example": "crit1",
#           "type": "string"
#         },
#         "description": {
#           "example": "Criterion 1",
#           "type": "string"
#         },
#         "ratings": {
#           "type": "array",
#           "items": { "$ref": "RubricRating" }
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
#           "example": "2013-08-28T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "example": "2013-08-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
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
#         "assignment_group_id": {
#           "description": "the ID of the assignment's group",
#           "example": 2,
#           "type": "integer"
#         },
#         "allowed_extensions": {
#           "description": "Allowed file extensions, which take effect if submission_types includes 'online_upload'.",
#           "example": "[\"docx\", \"ppt\"]",
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "turnitin_enabled": {
#           "description": "Boolean flag indicating whether or not Turnitin has been enabled for the assignment. NOTE: This flag will not appear unless your account has the Turnitin plugin available",
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
#           "description": "(Optional) assignment's settings for external tools if submission_types include 'external_tool'. Only url and new_tab are included. Use the 'External Tools' API if you need more information about an external tool.",
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
#         "position": {
#           "description": "the sorting order of the assignment in the group",
#           "example": 1,
#           "type": "integer"
#         },
#         "post_to_sis": {
#           "example": true,
#           "type" : "boolean",
#           "description" : "(optional, present if Post Grades to SIS feature is enabled)"
#         },
#         "integration_id": {
#           "example": "12341234",
#           "type" : "string",
#           "description" : "(optional, Third Party unique identifier for Assignment)"
#         },
#         "integration_data": {
#           "example": "12341234",
#           "type" : "string",
#           "description" : "(optional, Third Party integration data for assignment)"
#         },
#         "muted": {
#           "description": "whether the assignment is muted",
#           "type": "boolean"
#         },
#         "points_possible": {
#           "description": "the maximum points possible for the assignment",
#           "example": 12,
#           "type": "integer"
#         },
#         "submission_types": {
#           "description": "the types of submissions allowed for this assignment list containing one or more of the following: 'discussion_topic', 'online_quiz', 'on_paper', 'none', 'external_tool', 'online_text_entry', 'online_url', 'online_upload' 'media_recording'",
#           "example": "[\"online_text_entry\"]",
#           "type": "array",
#           "items": {"type": "string"},
#           "allowableValues": {
#             "values": [
#               "discussion_topic",
#               "online_quiz",
#               "on_paper",
#               "none",
#               "external_tool",
#               "online_text_entry",
#               "online_url",
#               "online_upload",
#               "media_recording"
#             ]
#           }
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
#           "description": "(Only visible if 'enable draft' account setting is on) whether the assignment is published",
#           "example": true,
#           "type": "boolean"
#         },
#         "unpublishable": {
#           "description": "(Only visible if 'enable draft' account setting is on) Whether the assignment's 'published' state can be changed to false. Will be false if there are student submissions for the assignment.",
#           "example": false,
#           "type": "boolean"
#         },
#         "only_visible_to_overrides": {
#           "description": "(Only visible if the Differentiated Assignments course feature is turned on) Whether the assignment is only visible to overrides.",
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
#           "example": "[\"title\"]",
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "submission": {
#           "description": "(Optional) If 'submission' is included in the 'include' parameter, includes a Submission object that represents the current user's (user who is requesting information from the api) current submission for the assignment. See the Submissions API for an example response. If the user does not have a submission, this key will be absent.",
#           "example": "{}",
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
#           "$ref": "RubricCriteria"
#         },
#         "assignment_visibility": {
#           "description": "(Optional) If 'assignment_visibility' is included in the 'include' parameter, includes an array of student IDs who can see this assignment.",
#           "example": "[137,381,572]",
#           "type": "array"
#         }
#       }
#     }
class AssignmentsApiController < ApplicationController
  before_filter :require_context
  include Api::V1::Assignment
  include Api::V1::Submission
  include Api::V1::AssignmentOverride

  # @API List assignments
  # Returns the list of assignments for the current context.
  # @argument include[] [String, "submission"|"assignment_visibility"]
  #   Associations to include with the assignment. The "assignment_visibility" option
  #   requires that the Differentiated Assignments course feature be turned on.
  # @argument search_term [Optional, String]
  #   The partial title of the assignments to match and return.
  # @argument override_assignment_dates [Optional, Boolean]
  #   Apply assignment overrides for each assignment, defaults to true.
  # @returns [Assignment]
  def index
    if authorized_action(@context, @current_user, :read)
      scope = @context.active_assignments.
          includes(:assignment_group, :rubric_association, :rubric).
          reorder("assignment_groups.position, assignments.position")

      scope = Assignment.search_by_attribute(scope, :title, params[:search_term])

      # fake assignment used for checking if the @current_user can read unpublished assignments
      fake = @context.assignments.scoped.new
      fake.workflow_state = 'unpublished'

      if @context.feature_enabled?(:draft_state) && !fake.grants_right?(@current_user, session, :read)
        # user should not see unpublished assignments
        scope = scope.published
      end

      # TODO temporary! remote this default_per_page parameter once dependent
      # applications have had a change to start honoring the pagination
      assignments = Api.paginate(scope, self, api_v1_course_assignments_url(@context), default_per_page: Api.max_per_page)

      if Array(params[:include]).include?('submission')
        submissions = Hash[
          @context.submissions.
            where(:assignment_id => assignments).
            for_user(@current_user).
            map { |s| [s.assignment_id,s] }
        ]
      else
        submissions = {}
      end

      override_param = params[:override_assignment_dates] || true
      override_dates = value_to_boolean(override_param)
      if override_dates
        Assignment.send(:preload_associations, assignments, :assignment_overrides)
        assignments.select{ |a| a.assignment_overrides.size == 0 }.
          each { |a| a.has_no_overrides = true }
      end

      include_visibility = Array(params[:include]).include?('assignment_visibility')

      hashes = assignments.map do |assignment|
        submission = submissions[assignment.id]
        assignment_json(assignment, @current_user, session,
                        submission: submission, override_dates: override_dates,
                        include_visibility: include_visibility)
      end

      render :json => hashes
    end
  end

  # @API Get a single assignment
  # Returns the assignment with the given id.
  # @argument include[] [String, "submission"|"assignment_visibility"]
  #   Associations to include with the assignment. The "assignment_visibility" option
  #   requires that the Differentiated Assignments course feature be turned on.
  # @argument override_assignment_dates [Optional, Boolean]
  #   Apply assignment overrides to the assignment, defaults to true.
  # @returns Assignment
  def show
    @assignment = @context.active_assignments.find(params[:id],
        :include => [:assignment_group, :rubric_association, :rubric])
    if authorized_action(@assignment, @current_user, :read)
      if Array(params[:include]).include?('submission')
        submission = @assignment.submissions.for_user(@current_user).first
      end

      include_visibility = Array(params[:include]).include?('assignment_visibility')

      override_param = params[:override_assignment_dates] || true
      override_dates = value_to_boolean(override_param)

      @assignment.context_module_action(@current_user, :read) unless @assignment.locked_for?(@current_user, :check_policies => true)
      render :json => assignment_json(@assignment, @current_user, session,
                                      submission: submission,
                                      override_dates: override_dates,
                                      include_visibility: include_visibility)
    end
  end

  # @API Create an assignment
  # Create a new assignment for this course. The assignment is created in the
  # active state.
  #
  # @argument assignment[name] [String] The assignment name.
  #
  # @argument assignment[position] [Optional, Integer]
  #   The position of this assignment in the group when displaying
  #   assignment lists.
  #
  # @argument assignment[submission_types][] [String, "online_quiz"|"none"|"on_paper"|"online_quiz"|"discussion_topic"|"external_tool"|"online_upload"|"online_text_entry"|"online_url"|"media_recording"]
  #   List of supported submission types for the assignment.
  #   Unless the assignment is allowing online submissions, the array should
  #   only have one element.
  #
  #   If not allowing online submissions, your options are:
  #     "online_quiz"
  #     "none"
  #     "on_paper"
  #     "online_quiz"
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
  # @argument assignment[allowed_extensions][] [Optional, String]
  #   Allowed extensions if submission_types includes "online_upload"
  #
  #   Example:
  #     allowed_extensions: ["docx","ppt"]
  #
  # @argument assignment[turnitin_enabled] [Optional, Boolean]
  #   Only applies when the Turnitin plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles Turnitin submissions for the assignment.
  #   Will be ignored if Turnitin is not available for the course.
  #
  # @argument assignment[integration_data] [Optional]
  #   Data related to third party integrations, JSON string required.
  #
  # @argument assignment[integration_id] [Optional]
  #   Unique ID from third party integrations
  #
  # @argument assignment[turnitin_settings] [Optional]
  #   Settings to send along to turnitin. See Assignment object definition for
  #   format.
  #
  # @argument assignment[peer_reviews] [Optional, Boolean]
  #   If submission_types does not include external_tool,discussion_topic,
  #   online_quiz, or on_paper, determines whether or not peer reviews
  #   will be turned on for the assignment.
  #
  # @argument assignment[automatic_peer_reviews] [Optional, Boolean]
  #   Whether peer reviews will be assigned automatically by Canvas or if
  #   teachers must manually assign peer reviews. Does not apply if peer reviews
  #   are not enabled.
  #
  # @argument assignment[notify_of_update] [Optional, Boolean]
  #   If true, Canvas will send a notification to students in the class
  #   notifying them that the content has changed.
  #
  # @argument assignment[group_category_id] [Optional, Integer]
  #   If present, the assignment will become a group assignment assigned
  #   to the group.
  #
  # @argument assignment[grade_group_students_individually] [Optional, Integer]
  #   If this is a group assignment, teachers have the options to grade
  #   students individually. If false, Canvas will apply the assignment's
  #   score to each member of the group. If true, the teacher can manually
  #   assign scores to each member of the group.
  #
  # @argument assignment[external_tool_tag_attributes] [Optional]
  #   Hash of attributes if submission_types is ["external_tool"]
  #   Example:
  #     external_tool_tag_attributes: {
  #       // url to the external tool
  #       url: "http://instructure.com",
  #       // create a new tab for the module, defaults to false.
  #       new_tab: false
  #     }
  #
  # @argument assignment[points_possible] [Optional, Float]
  #   The maximum points possible on the assignment.
  #
  # @argument assignment[grading_type] [Optional, "pass_fail"|"percent"|"letter_grade"|"gpa_scale"|"points"]
  #  The strategy used for grading the assignment.
  #  The assignment is ungraded if this field is omitted.
  #
  # @argument assignment[due_at] [Optional, Timestamp]
  #   The day/time the assignment is due.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[lock_at] [Optional, Timestamp]
  #   The day/time the assignment is locked after.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[unlock_at] [Optional, Timestamp]
  #   The day/time the assignment is unlocked.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[description] [Optional, String]
  #   The assignment's description, supports HTML.
  #
  # @argument assignment[assignment_group_id] [Optional, Integer]
  #   The assignment group id to put the assignment in.
  #   Defaults to the top assignment group in the course.
  #
  # @argument assignment[muted] [Optional, Boolean]
  #   Whether this assignment is muted.
  #   A muted assignment does not send change notifications
  #   and hides grades from students.
  #   Defaults to false.
  #
  # @argument assignment[assignment_overrides][] [Optional, AssignmentOverride]
  #   List of overrides for the assignment.
  #   NOTE: The assignment overrides feature is in beta.
  #
  # @argument assignment[only_visible_to_overrides] [Optional, Boolean]
  #   Whether this assignment is only visible to overrides
  #   (Only useful if 'differentiated assignments' account setting is on)
  #
  # @argument assignment[published] [Optional, Boolean]
  #   Whether this assignment is published.
  #   (Only useful if 'draft state' account setting is on)
  #   Unpublished assignments are not visible to students.
  #
  # @argument assignment[grading_standard_id] [Optional, Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
  #   This will update the grading_type for the course to 'letter_grade' unless it is already 'gpa_scale'.
  #
  # @returns Assignment
  def create
    @assignment = @context.assignments.build
    @assignment.workflow_state = 'unpublished' if @context.feature_enabled?(:draft_state)
    if authorized_action(@assignment, @current_user, :create)
      save_and_render_response
    end
  end

  # @API Edit an assignment
  # Modify an existing assignment.
  #
  # @argument assignment[name] [Optional, String] The assignment name.
  #
  # @argument assignment[position] [Optional, Integer]
  #   The position of this assignment in the group when displaying
  #   assignment lists.
  #
  # @argument assignment[submission_types][] [Optional, String, "online_quiz"|"none"|"on_paper"|"online_quiz"|"discussion_topic"|"external_tool"|"online_upload"|"online_text_entry"|"online_url"|"media_recording"]
  #   List of supported submission types for the assignment.
  #   Unless the assignment is allowing online submissions, the array should
  #   only have one element.
  #
  #   If not allowing online submissions, your options are:
  #     "online_quiz"
  #     "none"
  #     "on_paper"
  #     "online_quiz"
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
  # @argument assignment[allowed_extensions][] [Optional, String]
  #   Allowed extensions if submission_types includes "online_upload"
  #
  #   Example:
  #     allowed_extensions: ["docx","ppt"]
  #
  # @argument assignment[turnitin_enabled] [Optional, Boolean]
  #   Only applies when the Turnitin plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles Turnitin submissions for the assignment.
  #   Will be ignored if Turnitin is not available for the course.
  #
  # @argument assignment[turnitin_settings] [Optional]
  #   Settings to send along to turnitin. See Assignment object definition for
  #   format.
  #
  # @argument assignment[peer_reviews] [Optional, Boolean]
  #   If submission_types does not include external_tool,discussion_topic,
  #   online_quiz, or on_paper, determines whether or not peer reviews
  #   will be turned on for the assignment.
  #
  # @argument assignment[automatic_peer_reviews] [Optional, Boolean]
  #   Whether peer reviews will be assigned automatically by Canvas or if
  #   teachers must manually assign peer reviews. Does not apply if peer reviews
  #   are not enabled.
  #
  # @argument assignment[notify_of_update] [Optional, Boolean]
  #   If true, Canvas will send a notification to students in the class
  #   notifying them that the content has changed.
  #
  # @argument assignment[group_category_id] [Optional, Integer]
  #   If present, the assignment will become a group assignment assigned
  #   to the group.
  #
  # @argument assignment[grade_group_students_individually] [Optional, Integer]
  #   If this is a group assignment, teachers have the options to grade
  #   students individually. If false, Canvas will apply the assignment's
  #   score to each member of the group. If true, the teacher can manually
  #   assign scores to each member of the group.
  #
  # @argument assignment[external_tool_tag_attributes] [Optional]
  #   Hash of attributes if submission_types is ["external_tool"]
  #   Example:
  #     external_tool_tag_attributes: {
  #       // url to the external tool
  #       url: "http://instructure.com",
  #       // create a new tab for the module, defaults to false.
  #       new_tab: false
  #     }
  #
  # @argument assignment[points_possible] [Optional, Float]
  #   The maximum points possible on the assignment.
  #
  # @argument assignment[grading_type] [Optional, "pass_fail"|"percent"|"letter_grade"|"gpa_scale"|"points"]
  #  The strategy used for grading the assignment.
  #  The assignment is ungraded if this field is omitted.
  #
  # @argument assignment[due_at] [Optional, Timestamp]
  #   The day/time the assignment is due.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[lock_at] [Optional, Timestamp]
  #   The day/time the assignment is locked after.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[unlock_at] [Optional, Timestamp]
  #   The day/time the assignment is unlocked.
  #   Accepts times in ISO 8601 format, e.g. 2014-10-21T18:48:00Z.
  #
  # @argument assignment[description] [Optional, String]
  #   The assignment's description, supports HTML.
  #
  # @argument assignment[assignment_group_id] [Optional, Integer]
  #   The assignment group id to put the assignment in.
  #   Defaults to the top assignment group in the course.
  #
  # @argument assignment[muted] [Optional, Boolean]
  #   Whether this assignment is muted.
  #   A muted assignment does not send change notifications
  #   and hides grades from students.
  #   Defaults to false.
  #
  # @argument assignment[assignment_overrides][] [Optional, AssignmentOverride]
  #   List of overrides for the assignment.
  #   NOTE: The assignment overrides feature is in beta.
  #
  # @argument assignment[only_visible_to_overrides] [Optional, Boolean]
  #   Whether this assignment is only visible to overrides
  #   (Only useful if 'differentiated assignments' account setting is on)
  #
  # @argument assignment[published] [Optional, Boolean]
  #   Whether this assignment is published.
  #   (Only useful if 'draft state' account setting is on)
  #   Unpublished assignments are not visible to students.
  #
  # @argument assignment[grading_standard_id] [Optional, Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
  #   This will update the grading_type for the course to 'letter_grade' unless it is already 'gpa_scale'.
  #
  # If the assignment[assignment_overrides] key is absent, any existing
  # overrides are kept as is. If the assignment[assignment_overrides] key is
  # present, existing overrides are updated or deleted (and new ones created,
  # as necessary) to match the provided list.
  #
  # NOTE: The assignment overrides feature is in beta.
  #
  # @returns Assignment
  def update
    @assignment = @context.active_assignments.find(params[:id])
    if authorized_action(@assignment, @current_user, :update)
      save_and_render_response
    end
  end

  def save_and_render_response
    @assignment.content_being_saved_by(@current_user)
    if update_api_assignment(@assignment, params[:assignment], @current_user)
      render :json => assignment_json(@assignment, @current_user, session), :status => 201
    else
      errors = @assignment.errors.as_json[:errors]
      errors['published'] = errors.delete(:workflow_state) if errors.has_key?(:workflow_state)
      render :json => {errors: errors}, status: :bad_request
    end
  end
end
