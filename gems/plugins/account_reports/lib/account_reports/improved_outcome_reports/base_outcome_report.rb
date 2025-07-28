# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module AccountReports
  module ImprovedOutcomeReports
    class BaseOutcomeReport
      include ReportHelper

      COURSE_CACHE_SIZE = 32
      ORDER_OPTIONS = %w[users courses outcomes].freeze
      ORDER_SQL = { "users" => "u.id, learning_outcomes.id, c.id",
                    "courses" => "c.id, u.id, learning_outcomes.id",
                    "outcomes" => "learning_outcomes.id, u.id, c.id" }.freeze
      DEFAULT_ORDER = "u.id, learning_outcomes.id, c.id"

      def initialize(account_report)
        @account_report = account_report
        extra_text_term(@account_report)
        include_deleted_objects
      end

      private

      def determine_order_key
        param = @account_report.value_for_param("order")
        param = param.downcase if param
        select = ORDER_OPTIONS & [param]
        select.first if select.length == 1
      end

      def outcome_order
        ORDER_SQL[determine_order_key] || DEFAULT_ORDER
      end

      def map_order_to_columns(outcome_order)
        column_mapping = { "u.id" => "student id",
                           "c.id" => "course id",
                           "learning_outcomes.id" => "learning outcome id" }
        outcome_order.split(",").map do |x|
          column_mapping[x.strip]
        end
      end

      def canvas_next?(canvas, os_scope, os_index)
        return true if os_index >= os_scope.length

        order = map_order_to_columns(outcome_order)

        os = os_scope[os_index]
        order.each do |column|
          if canvas[column] != os[column]
            return canvas[column] < os[column]
          end
        end
        # default is to return true causing canvas data to appear before OS data
        # we will only default to this if all the order columns are equal
        true
      end

      def write_outcomes_report(headers, canvas_scope, config_options = {})
        config_options[:empty_scope_message] ||= "No outcomes found"
        config_options[:new_quizzes_scope] ||= []
        host = root_account.domain
        enable_i18n_features = true
        @account_level_mastery_scales_enabled = @account_report.account.root_account.feature_enabled?(:account_level_mastery_scales)

        os_scope = config_options[:new_quizzes_scope]

        write_report headers, enable_i18n_features do |csv|
          write_row = lambda do |row|
            row["assignment url"] = "https://#{host}" \
                                    "/courses/#{row["course id"]}" \
                                    "/assignments/#{row["assignment id"]}"
            row["submission date"] = default_timezone_format(row["submission date"])
            add_outcomes_data(row)
            csv << headers.map { |h| row[h] }
          end

          # Use post_process_record function to execute any transformation logic on records
          # Return processed record
          # Raise ActiveRecord:RecordInvalid to skip record
          post_process_record = config_options[:post_process_record]
          # post_process_record_cache is provided on each loop for the post_process_record function.
          # Use this hash to cache data between loops, e.g. skip querying data repeatedly from db
          # the hash MUST to be changed in place, otherwise it will not save changes
          post_process_record_cache = {}
          omitted_row_count = 0

          os_index = 0

          canvas_scope.find_each do |canvas_row|
            record_hash = canvas_row.attributes

            begin
              record_hash = post_process_record.call(record_hash, post_process_record_cache) if post_process_record
            rescue ActiveRecord::RecordInvalid
              omitted_row_count += 1
              next
            end

            until canvas_next?(record_hash, os_scope, os_index)
              write_row.call(os_scope[os_index])
              os_index += 1
            end
            write_row.call(record_hash)
          end

          total = os_scope.length + canvas_scope.except(:select).count - omitted_row_count
          GuardRail.activate(:primary) { AccountReport.where(id: @account_report.id).update_all(total_lines: total) }

          while os_index < os_scope.length
            write_row.call(os_scope[os_index])
            os_index += 1
          end

          csv << [config_options[:empty_scope_message]] if total == 0
        end
      end

      def proficiency(course)
        result = {}
        proficiency = course.resolved_outcome_proficiency
        ratings = proficiency_ratings(proficiency)
        result[:mastery_points] = ratings.find { |rating| rating[:mastery] }[:points]
        result[:points_possible] = ratings.first[:points]
        result[:ratings] = ratings
        result
      end

      def proficiency_ratings(proficiency)
        proficiency.outcome_proficiency_ratings.map do |rating_obj|
          convert_rating(rating_obj)
        end
      end

      def convert_rating(rating_obj)
        {
          description: rating_obj.description,
          points: rating_obj.points,
          mastery: rating_obj.mastery
        }
      end

      def set_score(row, outcome_data)
        total_percent = row["total percent outcome score"]
        if total_percent.present?
          points_possible = outcome_data[:points_possible]
          points_possible = outcome_data[:mastery_points] if points_possible.zero?
          score = points_possible * total_percent
        else
          score = if row["outcome score"].nil? || row["learning outcome points possible"].nil?
                    nil
                  else
                    (row["outcome score"] / row["learning outcome points possible"]) * outcome_data[:points_possible]
                  end
        end
        score
      end

      def set_rating(row, score, outcome_data)
        ratings = outcome_data[:ratings]&.sort_by { |r| r[:points] }&.reverse || []
        rating = ratings.detect { |r| r[:points] <= score } || {}
        row["learning outcome rating"] = rating[:description]
        rating
      end

      def hide_points(row)
        row["outcome score"] = nil
        row["learning outcome rating points"] = nil
        row["learning outcome points possible"] = nil
        row["learning outcome mastery score"] = nil
      end

      def find_cached_course(id)
        @course_cache ||= {}
        @course_cache[id] ||= begin
          @course_cache.delete(@course_cache.keys.first) if @course_cache.size >= COURSE_CACHE_SIZE
          Course.find(id)
        end
      end

      def add_outcomes_data(row)
        row["learning outcome mastered"] = unless row["learning outcome mastered"].nil?
                                             row["learning outcome mastered"] ? 1 : 0
                                           end

        outcome_data = if @account_level_mastery_scales_enabled &&
                          (course = find_cached_course(row["course id"])).resolved_outcome_proficiency.present?
                         proficiency(course)
                       elsif row["learning outcome data"].present?
                         YAML.safe_load(row["learning outcome data"])[:rubric_criterion]
                       else
                         LearningOutcome.default_rubric_criterion
                       end
        row["learning outcome mastery score"] = outcome_data[:mastery_points]
        score = set_score(row, outcome_data)
        rating = set_rating(row, score, outcome_data) if score.present?
        if row["assessment type"] != "quiz" && @account_level_mastery_scales_enabled
          row["learning outcome points possible"] = outcome_data[:points_possible]
        end
        if row["learning outcome points hidden"]
          hide_points(row)
        elsif rating.present?
          row["learning outcome rating points"] = rating[:points]
        end
      end
    end
  end
end
