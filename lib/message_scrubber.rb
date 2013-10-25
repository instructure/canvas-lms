#
# Copyright (C) 2013 Instructure, Inc.
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

# Public: Delete old (> 90 days) records from delayed_messages.
class MessageScrubber
  # Public: The minimum wait time in seconds between processing batches.
  MIN_DELAY = 1

  attr_reader :batch_size, :delay, :limit, :logger

  # Public: Create a new MessageScrubber.
  #
  # options - A settings hash. Accepted options are:
  #   - batch_size: The number of records to fetch at once (default: 1000).
  #   - delay: The delay, in seconds, between batches (default: 1).
  #   - logger: A logger object to log messages to (default: Rails.logger).
  def initialize(options = {})
    @batch_size = options.fetch(:batch_size, 1000)
    @limit      = Integer(Setting.get('message_scrubber_limit', 90)).days.ago
    @delay      = options.fetch(:delay, MIN_DELAY)
    @logger     = options.fetch(:logger, Rails.logger)
  end

  # Public: Delete old delayed messages on the current shard.
  #
  # options - A settings hash that accepts:
  #   - dry_run: If true, log the # of records affected but do not delete them (default: false).
  #
  # Returns nothing.
  def scrub(options = {})
    dry_run = options.fetch(:dry_run, false)
    scope   = DelayedMessage.where('send_at < ?', limit)
    dry_run ? log(scope) : delete_messages(scope)
  end

  # Public: Delete old delayed messages on all shards.
  #
  # options - A settings hash that accepts:
  #   - dry_run: If true, log the # of records affected but do not delete them (default: false).
  #
  # Returns nothing
  def scrub_all(options = {})
    Shard.with_each_shard { scrub(options) }
  end

  private

  # Internal: Delete the current batch of messages.
  #
  # scope - The ActiveRecord scope to work on.
  #
  # Returns the number of records deleted.
  def delete_messages(scope)
    count = scope.limit(batch_size).delete_all
    total = count
    while count > 0
      sleep(delay)
      count = scope.limit(batch_size).delete_all
      total += count
    end

    total
  end

  # Internal: Log expected action.
  #
  # scope - The ActiveRecord scope to log.
  #
  # Returns nothing.
  def log(scope)
    logger.info("MessageScrubber: #{scope.count} records would be deleted (older than #{limit})")
  end
end
