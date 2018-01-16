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

class CommunicationChannel
  class BulkActions
    # Maximum number of results to send back in a CSV report. The minimum of this and the individual reset action's
    # bulk_limit will be used to limit the number of results returned.
    REPORT_LIMIT = 10_000

    attr_reader :account, :after, :before, :pattern, :path_type

    def initialize(account:, after: nil, before: nil, pattern: nil, path_type: nil, with_invalid_paths: false)
      @account, @pattern, @path_type, @with_invalid_paths = account, pattern, path_type, with_invalid_paths
      @after = Time.zone.parse(after) if after
      @before = Time.zone.parse(before) if before
    end

    def matching_channels(for_report: false)
      ccs = CommunicationChannel.unretired.where(user_id: User.of_account(account))

      # Limit to self.class.bulk_limit, or REPORT_LIMIT if it's less and for_report is true
      ccs = ccs.limit([(REPORT_LIMIT if for_report), self.class.bulk_limit].compact.min)

      ccs = filter(ccs)
      ccs = ccs.path_like(pattern.tr('*', '%')) if pattern
      ccs = ccs.where(path_type: path_type) if path_type
      ccs = ccs.where("path_type != 'email' or lower(path) LIKE '%_@%_.%_'") unless @with_invalid_paths

      ccs
    end

    def count
      Shackles.activate(:slave) do
        matching_channels.count
      end
    end

    def report
      Shackles.activate(:slave) do
        CSV.generate do |csv|
          columns = self.class.report_columns

          csv << [
            I18n.t('User ID'),
            I18n.t('Name'),
            I18n.t('Communication channel ID'),
            I18n.t('Type'),
            I18n.t('Path')
          ] + columns.keys

          matching_channels(for_report: true).preload(:user).each do |cc|
            csv << [
              cc.user.id,
              cc.user.name,
              cc.id,
              cc.path_type,
              cc.path_description
            ] + columns.values.map { |value_generator| value_generator.to_proc.call(cc) }
          end
        end
      end
    end

    class ResetBounceCounts < BulkActions
      def self.bulk_limit
        1000
      end

      def self.report_columns
        {
          I18n.t('Date of most recent bounce') => :last_bounce_at,
          I18n.t('Bounce reason') => :last_bounce_summary
        }
      end

      def filter(ccs)
        ccs = ccs.where('bounce_count > 0').order(:last_bounce_at)
        ccs = ccs.where('last_bounce_at < ?', before) if before
        ccs = ccs.where('last_bounce_at > ?', after) if after
        ccs
      end


      def perform!
        send_later(:reset_bounce_counts!)
        {scheduled_reset_approximate_count: count}
      end

      private def reset_bounce_counts!
        matching_channels.to_a.each(&:reset_bounce_count!)
      end
    end

    class Confirm < BulkActions
      def self.bulk_limit
        10_000
      end

      def self.report_columns
        {
          I18n.t('Created at') => :created_at
        }
      end

      def filter(ccs)
        ccs = ccs.where(workflow_state: 'unconfirmed').order(:created_at)
        ccs = ccs.where('created_at < ?', before) if before
        ccs = ccs.where('created_at > ?', after) if after
        ccs
      end

      def perform!
        {confirmed_count: matching_channels.update_all(workflow_state: 'active')}
      end
    end
  end
end
