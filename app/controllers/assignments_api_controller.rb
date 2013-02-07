#
# Copyright (C) 2011 Instructure, Inc.
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
# @object Assignment
#     {
#       // the ID of the assignment
#       id: 4,
#
#       // the name of the assignment
#       name: "some assignment",
#
#       // the assignment description, in an HTML fragment
#       description: "<p>Do the following:</p>...",
#
#       // the due date for the assignment. returns null if not present.
#       due_at: "2012-07-01T23:59:00-06:00",
#
#       // the lock date (assignment is locked after this date). returns
#       // null if not present.
#       lock_at: "2012-07-01T23:59:00-06:00",
#
#       // the unlock date (assignment is unlocked after this date)
#       // returns null if not present
#       unlock_at: "2012-07-01T23:59:00-06:00",
#
#       // the ID of the course the assignment belongs to
#       course_id: 123,
#
#       // the URL to the assignment's web page
#       html_url: "http://canvas.example.com/courses/123/assignments/4",
#
#       // the ID of the assignment's group
#       assignment_group_id: 2,
#
#       // Allowed file extensions, which take effect if submission_types
#       // includes "online_upload".
#       allowed_extensions: [ "docx", "ppt" ],
#
#       // Boolean flag indicating whether or not Turnitin has been enabled
#       // for the assignment.
#       // NOTE: This flag will not appear unless your account has the
#       // Turnitin plugin available
#       turnitin_enabled: true,
#
#       // Settings to pass along to turnitin to control what kinds of matches
#       // should be considered.
#       // originality_report_visibility can be 'immediate', 'after_grading', or 'after_due_date'
#       // exclude_small_matches_type can be null, 'percent', 'words'
#       // exclude_small_matches_value:
#       // - if type is null, this will be null also
#       // - if type is 'percent', this will be a number between 0 and 100
#       //   representing match size to exclude as a percentage of the document size.
#       // - if type is 'words', this will be number > 0 representing how many
#       //   words a match must contain for it to be considered
#       // NOTE: This flag will not appear unless your account has the
#       // Turnitin plugin available
#       turnitin_settings: {
#         originality_report_visibility => 'after_grading',
#         s_paper_check => false,
#         internet_check => false,
#         journal_check => false,
#         exclude_biblio => false,
#         exclude_quoted => false,
#         exclude_small_matches_type => 'percent',
#         exclude_small_matches_value => 50,
#       },
#
#       // If this is a group assignment, boolean flag indicating whether or
#       // not students will be graded individually.
#       grade_group_students_individually: false,
#
#       // (Optional) assignment's settings for external tools if
#       // submission_types include "external_tool".
#       // Only url and new_tab are included.
#       // Use the "External Tools" API if you need more information about
#       // an external tool.
#       external_tool_tag_attributes: {
#         // URL to the external tool
#         url: "http://instructure.com",
#         // Whether or not there is a new tab for the external tool
#         new_tab: false
#       },
#
#       // Boolean indicating if peer reviews are required for this assignment
#       peer_reviews: false,
#
#       // Boolean indicating peer reviews are assigned automatically.
#       // If false, the teacher is expected to manually assign peer reviews.
#       automatic_peer_reviews: false,
#
#       // Integer representing the amount of reviews each user is assigned.
#       // NOTE: This key is NOT present unless you have automatic_peer_reviews
#       // set to true.
#       peer_review_count: 0,
#
#       // String representing a date the reviews are due by. Must be a date
#       // that occurs after the default due date. If blank, or date is not
#       // after the assignment's due date, the assignment's due date will
#       // be used.
#       // NOTE: This key is NOT present unless you have automatic_peer_reviews
#       // set to true.
#       peer_reviews_assign_at: "2012-07-01T23:59:00-06:00",
#
#
#       // the ID of the assignment’s group set (if this is a group assignment)
#       group_category_id: 1,
#
#       // if the requesting user has grading rights, the number of submissions that need grading.
#       needs_grading_count: 17,
#
#       // the sorting order of the assignment in the group
#       position: 1,
#
#       // the URL to the Canvas web UI page for the assignment
#       html_url: "https://...",
#
#       // whether the assignment is muted
#       muted: false,
#
#       // the maximum points possible for the assignment
#       points_possible: 12,
#
#       // the types of submissions allowed for this assignment
#       // list containing one or more of the following:
#       // "discussion_topic", "online_quiz", "on_paper", "none",
#       // "external_tool", "online_text_entry", "online_url", "online_upload"
#       // "media_recording"
#       submission_types: ["online_text_entry"],
#
#       // The type of grading the assignment receives; one of "pass_fail",
#       // "percent", "letter_grade", "points"
#       grading_type: "points",
#
#       // (Optional) explanation of lock status
#       lock_explanation: "This assignment is locked until September 1 at 12:00am",
#
#       // (Optional) whether anonymous submissions are accepted (applies only to quiz assignments)
#       anonymous_submissions: false,
#
#       // (Optional) the DiscussionTopic associated with the assignment, if applicable
#       discussion_topic: { ... },
#
#       // (Optional) Boolean indicating if assignment will be frozen when it is copied.
#       // NOTE: This field will only be present if the AssignmentFreezer
#       // plugin is available for your account.
#       freeze_on_copy: false,
#
#       // (Optional) Boolean indicating if assignment is frozen for the calling user.
#       // NOTE: This field will only be present if the AssignmentFreezer
#       // plugin is available for your account.
#       frozen: false,
#
#       // (Optional) Array of frozen attributes for the assignment.
#       // Only account administrators currently have permission to
#       // change an attribute in this list. Will be empty if no attributes
#       // are frozen for this assignment.
#       // NOTE: This field will only be present if the AssignmentFreezer
#       // plugin is available for your account.
#       frozen_attributes: [ "title" ],
#
#       // (Optional) If true, the rubric is directly tied to grading the assignment.
#       // Otherwise, it is only advisory. Included if there is an associated rubric.
#       use_rubric_for_grading: true,
#
#       // (Optional) An object describing the basic attributes of the rubric, including
#       // the point total. Included if there is an associated rubric.
#       rubric_settings: {
#         points_possible: 12
#       },
#
#       // (Optional) A list of scoring criteria and ratings for each rubric criterion.
#       // Included if there is an associated rubric.
#       rubric: [
#         {
#           "points": 10,
#           "id": "crit1",
#           "description": "Criterion 1",
#           "ratings": [
#             {
#               "points": 10,
#               "id": "rat1",
#               "description": "Full marks"
#             },
#             {
#               "points": 7,
#               "id": "rat2",
#               "description": "Partial answer"
#             },
#             {
#               "points": 0,
#               "id": "rat3",
#               "description": "No marks"
#             }
#           ]
#         },
#         {
#           "points": 2,
#           "id": "crit2",
#           "description": "Criterion 2",
#           "ratings": [
#             {
#               "points": 2,
#               "id": "rat1",
#               "description": "Pass"
#             },
#             {
#               "points": 0,
#               "id": "rat2",
#               "description": "Fail"
#             }
#           ]
#         }
#       ]
#     }
#
class AssignmentsApiController < ApplicationController
  before_filter :require_context

  include Api::V1::Assignment
  include Api::V1::AssignmentOverride

  # @API List assignments
  # Returns the list of assignments for the current context.
  # @returns [Assignment]
  def index
    if authorized_action(@context, @current_user, :read)
      @assignments = @context.active_assignments.find(:all,
          :include => [:assignment_group, :rubric_association, :rubric],
          :order => "assignment_groups.position, assignments.position")

      hashes = @assignments.map { |assignment|
        assignment_json(assignment, @current_user, session) }

      render :json => hashes.to_json
    end
  end

  # @API Get a single assignment
  # Returns the assignment with the given id.
  # @returns Assignment
  def show
    if authorized_action(@context, @current_user, :read)
      @assignment = @context.active_assignments.find(params[:id],
          :include => [:assignment_group, :rubric_association, :rubric])

      @assignment.context_module_action(@current_user, :read) unless @assignment.locked_for?(@current_user, :check_policies => true)
      render :json => assignment_json(@assignment, @current_user, session)
    end
  end

  # @API Create an assignment
  # Create a new assignment for this course. The assignment is created in the
  # active state.
  #
  # @argument assignment[name] The assignment name.
  #
  # @argument assignment[position] [Integer]
  #   The position of this assignment in the group when displaying
  #   assignment lists.
  #
  # @argument assignment[submission_types] [Array]
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
  #     "online_media_recording"
  #     "online_text_entry"
  #     "online_url"
  #     "online_media_recording" Only valid when the Kaltura plugin is enabled.
  #
  # @argument assignment[allowed_extensions] [Array]
  #   Allowed extensions if submission_types includes "online_upload"
  #
  #   Example:
  #     allowed_extensions: ["docx","ppt"]
  #
  # @argument assignment[turnitin_enabled] [Optional,Boolean]
  #   Only applies when the Turnitin plugin is enabled for a course and
  #   the submission_types array includes "online_upload".
  #   Toggles Turnitin submissions for the assignment.
  #   Will be ignored if Turnitin is not available for the course.
  #
  # @argument assignment[turnitin_settings] [Optional]
  #   Settings to send along to turnitin. See Assignment object definition for
  #   format.
  #
  # @argument assignment[peer_reviews] [Optional,Boolean]
  #   If submission_types does not include external_tool,discussion_topic,
  #   online_quiz, or on_paper, determines whether or not peer reviews
  #   will be turned on for the assignment.
  #
  # @argument assignment[automatic_peer_reviews] [Optional,Boolean]
  #   Whether peer reviews will be assigned automatically by Canvas or if
  #   teachers must manually assign peer reviews. Does not apply if peer reviews
  #   are not enabled.
  #
  # @argument assignment[notify_of_update] [Optional,Boolean]
  #   If true, Canvas will send a notification to students in the class
  #   notifying them that the content has changed.
  #
  # @argument assignment[group_category_id] [Optional,Integer]
  #   If present, the assignment will become a group assignment assigned
  #   to the group.
  #
  # @argument assignment[grade_group_students_individually] [Optional,Integer]
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
  # @argument assignment[points_possible] [Float] The maximum points possible on
  #   the assignment.
  #
  # @argument assignment[grading_type] [Optional, "pass_fail"|"percent"|"letter_grade"|"points"]
  #  The strategy used for grading the assignment.
  #  The assignment is ungraded if this field is omitted.
  # @argument assignment[due_at] [Timestamp]
  #   The day/time the assignment is due.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument assignment[lock_at] [Timestamp]
  #   The day/time the assignment is locked after.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument assignment[unlock_at] [Timestamp]
  #   The day/time the assignment is unlocked.
  #   Accepts times in ISO 8601 format, e.g. 2011-10-21T18:48Z.
  #
  # @argument assignment[description] [String]
  #   The assignment's description, supports HTML.
  #
  # @argument assignment[assignment_group_id] [Integer]
  #   The assignment group id to put the assignment in.
  #   Defaults to the top assignment group in the course.
  #
  # @argument assignment[muted] [Boolean]
  #   Whether this assignment is muted.
  #   A muted assignment does not send change notifications
  #   and hides grades from students.
  #   Defaults to false.
  #
  # @argument assignment[assignment_overrides] [Optional, [AssignmentOverride]]
  #   List of overrides for the assignment.
  #   NOTE: The assignment overrides feature is in beta.
  #
  # @returns Assignment
  def create
    @assignment = @context.assignments.build

    if authorized_action(@assignment, @current_user, :create)
      save_and_render_response
    end
  end

  # @API Edit an assignment
  # Modify an existing assignment. See the documentation for assignment
  # creation.
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
    @assignment = @context.assignments.find(params[:id])

    if authorized_action(@assignment, @current_user, :update)
      save_and_render_response
    end
  end

  def save_and_render_response
    if update_and_save_assignment(@assignment, params[:assignment])
      render :json => assignment_json(@assignment, @current_user, session).to_json, :status => 201
    else
      # TODO: we don't really have a strategy in the API yet for returning
      # errors.
      render :json => "error".to_json, :status => 400
    end
  end

  protected

  def update_and_save_assignment(assignment, assignment_params)
    return if assignment_params.nil?

    # convert hashes like {0 => x, 1 => y} into arrays like [x, y]
    overrides = assignment_params[:assignment_overrides]
    if overrides.is_a?(Hash)
      return unless overrides.keys.all?{ |k| k.to_i.to_s == k.to_s }
      indices = overrides.keys.sort_by(&:to_i)
      return unless indices.map(&:to_i) == (0...indices.size).to_a
      overrides = indices.map{ |index| overrides[index] }
    end

    # require it to be formatted as an array if it's present
    return if overrides && !overrides.is_a?(Array)

    # do the updating
    update_api_assignment(assignment, assignment_params, false)
    if overrides
      assignment.transaction do
        assignment.save_without_broadcasting!
        batch_update_assignment_overrides(assignment, overrides)
      end
      assignment.do_notifications!
    else
      assignment.save!
    end
    return true
  rescue ActiveRecord::RecordInvalid
    return false
  end
end
