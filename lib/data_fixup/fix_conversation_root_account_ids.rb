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

module DataFixup
  module FixConversationRootAccountIds
    # they should have been relative to birth shard but they weren't q_q

    def self.run
      badness_day = DateTime.parse("2016-08-26")

      Conversation.find_ids_in_ranges do |min_id, max_id|
        Conversation.where(:id => min_id..max_id).where("updated_at > ?", badness_day).preload(:context).each do |conv|
          next unless conv.context
          broken_ra_id = conv.context.root_account_id
          if conv.root_account_ids.include?(broken_ra_id)
            # there no actual way that I know of to tell the difference between
            # a broken root account id and a frd one from the birth shard
            # ...
            # but that's just a risk we'll have to take

            ra_ids = conv.root_account_ids.dup
            ra_ids.delete(broken_ra_id)

            fixed_id = Shard.relative_id_for(broken_ra_id, Shard.current, Shard.birth)
            ra_ids << fixed_id unless ra_ids.include?(fixed_id)
            conv.root_account_ids = ra_ids

            conv.save

            conv.conversation_participants.each do |part|
              ra_ids = part.root_account_ids.split(",").map(&:to_i)
              if ra_ids.delete(broken_ra_id)
                ra_ids << fixed_id unless ra_ids.include?(fixed_id)
                part.root_account_ids = ra_ids.sort.join(",")
                part.save
              end
            end
          end
        end
      end
    end
  end
end
