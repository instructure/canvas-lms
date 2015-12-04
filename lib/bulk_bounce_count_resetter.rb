#
# Copyright (C) 2015 Instructure, Inc.
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

class BulkBounceCountResetter
  # Maximum number of channels we'll process in API calls to bulk endpoints
  # (bulk_reset_bounce_counts and bouncing_channel_report)
  BULK_LIMIT = 1000

  attr_reader :account, :after, :before, :pattern
  def initialize(account:, after: nil, before: nil, pattern: nil)
    @account, @pattern = account, pattern
    @after = Time.zone.parse(after) if after
    @before = Time.zone.parse(before) if before
  end

  def self.bulk_limit
    BULK_LIMIT
  end

  def bouncing_channels_for_account
    ccs = CommunicationChannel.unretired
          .where(user_id: User.of_account(account))
          .where('bounce_count > 0')
          .order(:last_bounce_at)
          .limit(self.class.bulk_limit)

    ccs = ccs.where('last_bounce_at > ?', after) if after
    ccs = ccs.where('last_bounce_at < ?', before) if before
    ccs = ccs.where('path ILIKE ?', pattern.tr('*', '%')) if pattern
    ccs
  end

  def count
    bouncing_channels_for_account.count
  end

  def bulk_reset_bounce_counts
    bouncing_channels_for_account.to_a.each(&:reset_bounce_count!).length
  end

  def bouncing_channel_report
    Shackles.activate(:slave) do
      CSV.generate do |csv|
        csv << [
          I18n.t('User ID'),
          I18n.t('Name'),
          I18n.t('Communication channel ID'),
          I18n.t('Path'),
          I18n.t('Date of most recent bounce'),
          I18n.t('Bounce reason')
        ]

        bouncing_channels_for_account.each do |cc|
          csv << [
            cc.user.id,
            cc.user.name,
            cc.id,
            cc.path,
            cc.last_bounce_at,
            cc.last_bounce_summary
          ]
        end
      end
    end
  end

end