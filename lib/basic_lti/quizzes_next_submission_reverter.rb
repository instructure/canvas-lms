# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module BasicLTI
  class QuizzesNextSubmissionReverter
    def initialize(submission, launch_url, grader_id)
      @submission = submission
      @launch_url = launch_url
      @grader_id = grader_id
    end

    # this method builds two versions/layers
    # 1: masking version, filtering target attempt from submission history
    #    this can reuse a version if the previous version has a same url (attempt identifier)
    # 2: version to be reverted, making sure the submission has a score from the
    #    previous attempt
    def revert_attempt
      # do nothing if there is no version for the requested attempt (identified by @launch_url)
      return true unless valid_revert?

      update_submission
      # we want to revert submission to the last attempt
      revert_to_last_attempt
      true
    end

    private

    def valid_revert?
      return false if @submission.blank? || @launch_url.blank? || target_attempt_version.blank?

      # can be reverted if submission has versions
      return false if @submission.versions.blank?

       # earlier attempt(version) cannot be reopened
       target_attempt_version[:url] == @launch_url
    end

    def revert_to_last_attempt
      # if version_to_be_reverted is nil, we don't want to revert to any version
      # @submission.submission_type = nil will protect an attempt from loading
      return if version_to_be_reverted.blank?

      # this will create an active/open version (to avoid overwriting the masking
      #   version, created in #update_submission)
      # the acive/open version is sync'ed with submission.
      # In this scenario, the open version is the version to be reverted.
      @submission.with_versioning(:explicit => true) { @submission.save! }
      @submission.revert_to_version(
        version_to_be_reverted[:number],
        # grade is a derived field, will be calculated automatically on saving
        except: [:grade]
      )
    end

    # the latest attempt (identified by @launch_url) version
    def target_attempt_version
      fetch_versions[1]
    end

    # the version we want to revert to
    def version_to_be_reverted
      fetch_versions[0]
    end

    def fetch_versions
      return @_fetch_versions if @_fetch_versions.present?
      # the latest version of the previous attempt (we want to revert to)
      prev_attempt_version = nil
      # the latest version of current attempt (identified by @launch_url)
      cur_attempt_version = nil
      unsubmitted_version = nil
      attempt_hash.each do |h|
        x, y, z = process_submission_hash(h)
        unsubmitted_version = x || unsubmitted_version
        prev_attempt_version = y || prev_attempt_version
        cur_attempt_version = z || cur_attempt_version
      end
      # revert the submission to a version of the last attempt, or
      #   unsubmitted version if there is no other attempts
      @_fetch_versions = [prev_attempt_version || unsubmitted_version, cur_attempt_version]
    end

    def process_submission_hash(h)
      url = h[:url]
      submitted_at = h[:submitted_at]
      # see QuizzesNextVersionedSubmission, a unsubmitted version (1st version) was created there
      # if the submission has only one version, and we want to reopen it,
      #   we want to revert the submission to unsubmitted.
      unsubmitted_version = h if h[:number] == 1 && submitted_at.blank?
      prev_attempt_version = nil
      cur_attempt_version = nil
      if url != @launch_url && valid_version?(h)
        prev_attempt_version = h
      elsif valid_version?(h)
        cur_attempt_version = h
      end
      [unsubmitted_version, prev_attempt_version, cur_attempt_version]
    end

    def valid_version?(h)
      url = h[:url]
      score = h[:score]
      url.present? && score.present?
    end

    def attempt_hash
      @_attempt_hash ||= begin
        vs = @submission.versions.map do |v|
          h = YAML.safe_load(v.yaml).with_indifferent_access
          { url: h[:url], submitted_at: h[:submitted_at], number: v.number, updated_at: h[:updated_at], score: h[:score] }
        end
        # we want versions in this order to be used in #fetch_versions
        vs.sort_by{ |x| [x[:submitted_at] || x[:updated_at], x[:number]] }
      end
    end

    # this creates a masking version, masking all versions from the target attempt
    # if the lastest version is from the same attempt, we can be smart to overwrite the version,
    #   instead of creating a new version
    def update_submission
      @submission.score = nil
      @submission.graded_at = @submission.submitted_at
      @submission.grade_matches_current_submission = false
      @submission.grader_id = @grader_id
      @submission.submission_type = nil
      # don't add a new version if the open version is from the same attempt
      return @submission.save! if @submission.url == @launch_url
      @submission.url = @launch_url
      @submission.with_versioning(:explicit => true) { @submission.save! }
    end
  end
end
