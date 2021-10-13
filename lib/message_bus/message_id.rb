# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

##
# Message Ids in pulsar are comparable
# WITHIN A PARTITION to give a consistent order to the messages
# when you want to store your own iterator state outside
# of the subscription mechanism pulsar provides.  This class
# takes care of parsing the string representation and doing
# comparisons between message ids.
module MessageBus
  class MessageId
    include Comparable

    attr_reader :partition_id, :ledger_id, :entry_id, :batch_index

    def initialize(ledger_id, entry_id, partition_id, batch_index)
      @ledger_id = ledger_id
      @entry_id = entry_id
      @partition_id = partition_id
      @batch_index = batch_index
    end

    # String representation looks something like "(2802,0,-1,0)".
    # You can interpret that as ledger_id, entry_id, partition_id, and batch_index.
    # generally we expect the partition_id to be -1 unless these messages are on a partitioned
    # topic.  Note that there is no defined ordering between messages from different partitions.
    def self.from_string(message_id_input)
      # when compacting strings and existing parsed values in a collection,
      # it's convenient to be able to transform them all to MessageId objects idempotently.
      return message_id_input if message_id_input.is_a?(::MessageBus::MessageId)

      components = message_id_input.gsub(/[()]/, "").split(",").map(&:to_i)
      raise ArgumentError, "Not a pulsar message id #{message_id_input}" unless components.size == 4

      MessageBus::MessageId.new(*components)
    end

    def self.from_hash(hash)
      MessageBus::MessageId.new(
        hash.fetch(:ledger_id).to_i,
        hash.fetch(:entry_id).to_i,
        hash.fetch(:partition_id).to_i,
        hash.fetch(:batch_index).to_i
      )
    end

    def <=>(other)
      if !other.is_a?(::MessageBus::MessageId) || other.partition_id != self.partition_id
        raise ArgumentError, "MessageID can only compare to other message IDs in the same partition"
      end

      return self.ledger_id <=> other.ledger_id unless other.ledger_id == self.ledger_id

      return self.entry_id <=> other.entry_id unless other.entry_id == self.entry_id

      self.batch_index <=> other.batch_index
    end

    def to_s
      "(#{ledger_id},#{entry_id},#{partition_id},#{batch_index})"
    end

    def to_h
      {
        partition_id: partition_id,
        ledger_id: ledger_id,
        entry_id: entry_id,
        batch_index: batch_index
      }
    end
  end
end
