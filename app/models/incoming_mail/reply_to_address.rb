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


# Public: Represents a reply-to address for a message.
class IncomingMail::ReplyToAddress
  attr_reader :message

  # Public: Error thrown when IncomingMail::ReplyToAddress is used with an empty address pool.
  class EmptyReplyAddressPool < StandardError
  end

  # Public: Create a new IncomingMail::ReplyToAddress.
  #
  # message - A Message object.
  def initialize(message)
    @message = message
  end

  # Public: Construct a reply-to address.
  #
  # Returns an email address string.
  def address
    return nil if message.path_type == 'sms'
    return message.from if message.context_type == 'ErrorReport'

    address, domain = self.class.address_from_pool(message).split('@')
    "#{address}+#{secure_id}-#{message.global_id}@#{domain}"
  end

  alias :to_s :address

  # Public: Generate the unique, secure ID for this address' message.
  #
  # Returns a secure ID string.
  def secure_id
    Canvas::Security.hmac_sha1(message.global_id.to_s)
  end

  class << self
    # Internal: An array of email addresses to be used in the reply-to field.
    attr_writer :address_pool

    # Public: Return a reply-to address from the class' address pool. Use a
    # modulo operation w/ the message ID to ensure that the same Reply-To is
    # always used for a given message.
    #
    # message - A message object to construct a reply-to address for.
    #
    # Returns an email address string.
    def address_from_pool(message)
      raise EmptyReplyAddressPool unless address_pool.present?
      index = if message.id.present?
                message.id % address_pool.length
              else
                rand(address_pool.length)
              end

      address_pool[index]
    end

    private
    # Internal: Array of email addresses to use as Reply-To addresses.
    attr_reader :address_pool
  end
end
