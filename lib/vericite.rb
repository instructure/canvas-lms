# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require "vericite_client"

module VeriCite
  def self.state_from_similarity_score(similarity_score)
    return "none" if similarity_score == 0
    return "acceptable" if similarity_score < 25
    return "warning" if similarity_score < 50
    return "problem" if similarity_score < 75

    "failure"
  end

  class Client
    attr_accessor :account_id, :shared_secret, :host, :testing, :show_preliminary_score

    def initialize(testing = false)
      @host = Canvas::Plugin.find(:vericite).settings[:host] || "api.vericite.com"
      account_id = Canvas::Plugin.find(:vericite).settings[:account_id]
      shared_secret = Canvas::Plugin.find(:vericite).settings[:shared_secret]
      show_preliminary_score = Canvas::Plugin.find(:vericite).settings[:show_preliminary_score] || false
      raise "Account ID required" unless account_id
      raise "Shared secret required" unless shared_secret

      @account_id = account_id
      @shared_secret = shared_secret
      @show_preliminary_score = show_preliminary_score
      @testing = testing
    end

    def id(obj)
      if @testing
        "test_#{obj.asset_string}"
      else
        "#{account_id}_#{obj.asset_string}"
      end
    end

    def email(item)
      # emails @example.com are, guaranteed by RFCs, to be like /dev/null :)
      email = if item.is_a?(User)
                item.email
              end
      email || "#{item.asset_string}@null.instructure.example.com"
    end

    def self.default_assignment_vericite_settings
      {
        originality_report_visibility: Canvas::Plugin.find(:vericite).settings[:release_to_students] || "immediate",
        exclude_quoted: Canvas::Plugin.find(:vericite).settings[:exclude_quotes],
        exclude_self_plag: Canvas::Plugin.find(:vericite).settings[:exclude_self_plag],
        store_in_index: Canvas::Plugin.find(:vericite).settings[:store_in_index],
        vericite: true
      }
    end

    def self.normalize_assignment_vericite_settings(settings)
      unless settings.nil?
        valid_keys = VeriCite::Client.default_assignment_vericite_settings.keys
        valid_keys << :created
        settings = settings.slice(*valid_keys)

        settings[:originality_report_visibility] = "immediate" unless %w[immediate after_grading after_due_date never].include?(settings[:originality_report_visibility])

        %i[exclude_quoted exclude_self_plag store_in_index].each do |key|
          bool = Canvas::Plugin.value_to_boolean(settings[key])
          settings[key] = bool ? "1" : "0"
        end
      end
      settings
    end

    def createOrUpdateAssignment(assignment, settings)
      course = assignment.context
      today = course.time_zone.today
      settings = VeriCite::Client.normalize_assignment_vericite_settings(settings)

      response = sendRequest(:create_assignment, settings.merge!({
                                                                   user: course,
                                                                   course:,
                                                                   assignment:,
                                                                   utp: "2",
                                                                   dtstart: "#{today.strftime} 00:00:00",
                                                                   dtdue: "#{today.strftime} 00:00:00",
                                                                   dtpost: "#{today.strftime} 00:00:00",
                                                                   late_accept_flag: "1",
                                                                   post: true
                                                                 }))

      is_response_success?(response) ? { assignment_id: response[:assignment_id] } : response_error_hash(response)
    end

    # if asset_string is passed in, only submit that attachment
    def submitPaper(submission, asset_string = nil)
      student = submission.user
      assignment = submission.assignment
      course = assignment.context
      opts = {
        post: true,
        utp: "1",
        user: student,
        course:,
        assignment:,
        tem: email(course),
        role: submission.grants_right?(student, :grade) ? "Instructor" : "Learner"
      }
      responses = {}
      if submission.submission_type == "online_upload"
        attachments = submission.attachments.select { |a| a.vericiteable? && (asset_string.nil? || a.asset_string == asset_string) }
        attachments.each do |a|
          # do not resubmit if the score already exists
          next unless submission.vericite_data_hash[a.asset_string][:similarity_score].blank?

          paper_id = a.id
          paper_title = File.basename(a.display_name, ".*")
          paper_ext = a.extension
          paper_type = a.content_type
          if paper_ext.nil?
            paper_ext = ""
          end
          paper_size = 100 # File.size(
          responses[a.asset_string] = sendRequest(:submit_paper, { pid: paper_id, ptl: paper_title, pext: paper_ext, ptype: paper_type, psize: paper_size, pdata: a.open }.merge!(opts))
        end
      elsif submission.submission_type == "online_text_entry" && (asset_string.nil? || submission.asset_string == asset_string)
        paper_id = Digest::SHA1.hexdigest submission.plaintext_body
        paper_ext = "html"
        paper_title = "InlineSubmission"
        plain_text = "<html>#{submission.plaintext_body}</html>"
        paper_type = "text/html"
        paper_size = plain_text.bytesize

        responses[submission.asset_string] = sendRequest(:submit_paper, { pid: paper_id, ptl: paper_title, pext: paper_ext, ptype: paper_type, psize: paper_size, pdata: plain_text }.merge!(opts))
      else
        raise "Unsupported submission type for VeriCite integration: #{submission.submission_type}"
      end

      responses.transform_values! do |res|
        is_response_success?(res) ? { object_id: res[:returned_object_id] } : response_error_hash(res)
      end

      responses
    end

    def generateReport(submission, asset_string)
      user = submission.user
      assignment = submission.assignment
      course = assignment.context
      object_id = submission.vericite_data_hash[asset_string][:object_id] rescue nil
      res = nil
      res = sendRequest(:get_scores, oid: object_id, utp: "2", user:, course:, assignment:) if object_id
      data = {}
      if res
        data[:similarity_score] = res[:similarity_score]
      end
      data
    end

    def submissionReportUrl(submission, current_user, asset_string)
      user = submission.user
      assignment = submission.assignment
      course = assignment.context
      object_id = submission.vericite_data_hash[asset_string][:object_id] rescue nil
      response = sendRequest(:generate_report, oid: object_id, utp: "2", current_user:, user:, course:, assignment:)
      if response.nil?
        nil
      else
        response[:report_url]
      end
    end

    def submissionStudentReportUrl(submission, current_user, asset_string)
      user = submission.user
      assignment = submission.assignment
      course = assignment.context
      object_id = submission.vericite_data_hash[asset_string][:object_id] rescue nil
      response = sendRequest(:generate_report, oid: object_id, utp: "1", current_user:, user:, course:, assignment:, tem: email(course))
      if response.nil?
        nil
      else
        response[:report_url]
      end
    end

    def sendRequest(command, args)
      # default response is "ok" since VeriCite doesn't implement all functions
      response = {}
      begin
        vericite_config = VeriCiteClient::Configuration.new
        vericite_config.host = @host
        vericite_config.base_path = "/lms/v1"
        api_client = VeriCiteClient::ApiClient.new(vericite_config)
        vericite_client = VeriCiteClient::DefaultApi.new(api_client)

        user = args.delete :user
        course = args.delete :course
        assignment = args.delete :assignment

        consumer = @account_id
        consumer_secret = @shared_secret
        case command
        when :create_assignment
          context_id = course.id
          assignment_id = assignment.id
          assignment_data = VeriCiteClient::AssignmentData.new
          assignment_data.assignment_title = assignment.title || assignment_id
          assignment_data.assignment_instructions = assignment.description || ""
          assignment_data.assignment_exclude_quotes = args["exclude_quoted"] == "1"
          assignment_data.assignment_exclude_self_plag = args["exclude_self_plag"] == "1"
          assignment_data.assignment_store_in_index = args["store_in_index"] == "1"
          assignment_data.assignment_due_date = 0
          unless assignment.due_at.nil?
            # convert to epoch time in milli
            assignment_data.assignment_due_date = assignment.due_at.to_time.utc.to_i * 1000
          end
          assignment_data.assignment_grade = assignment.points_possible || -1
          _data, status_code, _headers = vericite_client.assignments_context_id_assignment_id_post(context_id, assignment_id, consumer, consumer_secret, assignment_data)
          # check status code
          response[:return_code] = status_code
          unless is_response_success?(response)
            response[:return_message] = "An error has occurred while creating the VeriCite assignment."
            response[:public_error_message] = response[:return_message]
            raise "Failed to create assignment: #{assignment_id}, site #{context_id}"
          end
          # this is a flag to signal success
          response[:assignment_id] = assignment.id
        when :submit_paper
          context_id = course.id
          assignment_id = assignment.id
          user_id = user.id
          report_meta_data = VeriCiteClient::ReportMetaData.new
          report_meta_data.user_first_name = user.first_name
          report_meta_data.user_last_name = user.last_name
          report_meta_data.user_email = email(user)
          report_meta_data.user_role = args[:role]
          if assignment
            report_meta_data.assignment_title = assignment.title || assignment_id
          end
          if course
            report_meta_data.context_title = course.name || context_id
          end
          external_content_data = VeriCiteClient::ExternalContentData.new
          external_content_data.external_content_id = "#{consumer}/#{context_id}/#{assignment_id}/#{user_id}/#{args[:pid]}"
          external_content_data.file_name = args[:ptl]
          external_content_data.upload_content_type = args[:pext]
          external_content_data.upload_content_length = args[:psize]
          report_meta_data.external_content_data = external_content_data
          # @return [Array<ExternalContentUploadInfo>]
          data, status_code, _headers = vericite_client.reports_submit_request_context_id_assignment_id_user_id_post(context_id, assignment_id, user_id, consumer, consumer_secret, report_meta_data)
          # check status code
          response[:return_code] = status_code
          unless is_response_success?(response)
            response[:return_message] = "An error has occurred while submitting the paper to VeriCite."
            response[:public_error_message] = response[:return_message]
            raise "Failed to submit paper: #{external_content_data.external_content_id}"
          end
          data.each do |externalContentUploadInfo|
            # API will return an upload URL to store the submission (throws an exception if it fails)
            api_client.uploadfile(externalContentUploadInfo.url_post, args[:pdata], externalContentUploadInfo.headers)
          end
          # this is a flag to signal success
          response[:returned_object_id] = external_content_data.external_content_id
        when :get_scores
          context_id = course.id
          assignment_id = assignment.id
          user_id = user.id
          user_score_cache_key_prefix = "vericite_scores/#{consumer}/#{context_id}/#{assignment_id}/"
          users_score_map = {}
          # first check if the cache already has the user's score and if we haven't looked up this assignment lately:
          users_score_map[user_id.to_s] = Rails.cache.read("#{user_score_cache_key_prefix}#{user_id}")
          if users_score_map[user_id.to_s].nil? && Rails.cache.read(user_score_cache_key_prefix).nil?
            # we already looked up this user in Redis, don't bother again (by setting {})
            users_score_map[user_id.to_s] ||= {}
            # we need to look up the user scores in VeriCite for this course
            # @return [Array<ReportScoreReponse>]
            data, status_code, _headers = vericite_client.reports_scores_context_id_get(context_id, consumer, consumer_secret, { assignment_id: })
            # keep track of the assignment lookup api call
            Rails.cache.write(user_score_cache_key_prefix, true, expires_in: 5.minutes)
            # check status code
            response[:return_code] = status_code
            unless is_response_success?(response)
              response[:return_message] = "An error has occurred while getting scores from VeriCite."
              response[:public_error_message] = response[:return_message]
              raise "Failed to get scores for site: #{context_id}, assignment: #{assignment_id}, user: #{user_id},  exId: #{args[:oid]}"
            end
            # create the user scores map and cache it
            data.each do |reportScoreReponse|
              next unless reportScoreReponse.score.is_a?(Integer) && reportScoreReponse.score >= 0 &&
                          (@show_preliminary_score || reportScoreReponse.preliminary.nil? || !reportScoreReponse.preliminary)

              # keep track of this user's report scores
              users_score_map[reportScoreReponse.user] ||= {}
              users_score_map[reportScoreReponse.user][reportScoreReponse.external_content_id] = Float(reportScoreReponse.score)
            end
            # cache the user score map for a short period of time
            users_score_map.each_key do |key|
              Rails.cache.write("#{user_score_cache_key_prefix}#{key}", users_score_map[key], expires_in: 5.minutes)
            end
          else
            # since we didn't have to consult VeriCite, set response status to 200
            response[:return_code] = 200
          end

          # the user score map shouldn't be empty now (either grabbed from the cache or VeriCite)
          users_score_map[user_id.to_s]&.each do |key, score|
            if key == args[:oid] && score >= 0
              response[:similarity_score] = score
            end
          end
        when :generate_report
          context_id = course.id
          assignment_id_filter = assignment.id
          user_id = user.id
          current_user = args.delete :current_user
          token_user = current_user.id
          token_user_role = "Learner"
          if args[:utp] == "2"
            # instructor
            token_user_role = "Instructor"
          end
          # @return [Array<ReportURLLinkReponse>]
          data, status_code, _headers = vericite_client.reports_urls_context_id_get(context_id, assignment_id_filter, consumer, consumer_secret, token_user, token_user_role, { user_id_filter => user_id, external_content_id_filter => args[:oid] })
          # check status code
          response[:return_code] = status_code
          unless is_response_success?(response)
            response[:return_message] = "An error has occurred while getting the report URL from VeriCite."
            response[:public_error_message] = response[:return_message]
            raise "Failed to get the report url for site: #{context_id}, assignment: #{assignment_id}, user: #{user_id},  exId: #{args[:oid]}, token_user: #{token_user}, token_user_role: #{token_user_role}"
          end
          data.each do |reportURLLinkReponse|
            # should only be 1 url
            if reportURLLinkReponse.external_content_id == args[:oid]
              # setting response URL is a signal for success
              response[:report_url] = reportURLLinkReponse.url
            end
          end
        end
      rescue => e
        Rails.logger.error("VeriCite: account_id: #{@account_id}, code: #{response[:return_code]}, error: #{e}")
        if is_response_success?(response)
          # we do not want to return a success code if there was an error
          response[:return_code] = 100
        end
        unless response.key?(:return_message)
          # we want a generic error message at a minimum
          response[:return_message] = "VeriCite error during #{command} command, error: #{e}"
          response[:public_error_message] = response[:return_message]
        end
      end # begin

      return nil if @testing

      response
    end

    private

    SUCCESSFUL_RETURN_CODES = (200..299)
    def is_response_success?(response)
      response&.key?(:return_code) && SUCCESSFUL_RETURN_CODES.cover?(Integer(response[:return_code]))
    rescue
      false
    end

    def response_error_hash(response)
      return {} if is_response_success?(response)

      {
        error_code: response[:return_code],
        error_message: response[:return_message],
        public_error_message: response[:public_error_message],
      }
    end
  end
end
