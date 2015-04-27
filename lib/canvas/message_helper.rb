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

module Canvas::MessageHelper
  def self.default_message_path(filename)
    File.join(Rails.root.to_s, 'app', 'messages', filename)
  end

  def self.add_message_path(path)
    if File.exist?(path) && File.directory?(path)
      @message_paths ||= []
      @message_paths << path
    end
  end

  def self.find_message_path(filename)
    path = nil
    if @message_paths
      @message_paths.each do |mp|
        test_path = File.join(mp, filename)
        if File.exist?(test_path)
          path = test_path
          break
        end
      end
    end
    path || default_message_path(filename)
  end

  # Create or update a Notification entry.
  #
  # ==== Arguments
  # Accepts a backward compatible list of explicit parameters
  # or a hash of values (preferred).
  #
  # ==== Value Hash
  # * <tt>:category</tt> - Category name notification is
  #                        associated with.
  # * <tt>:name</tt> - Name of the notification.
  # * <tt>:delay_for</tt> - Delay in seconds. Assigned
  #                         to delay_for attribute.
  #
  # ==== Backward Compatible Arguments
  # Previous call signature: create_notification(context, type, delay, link, txt, sms="")
  #
  # Legacy Arguments
  # * context - ignored
  # * type - Mapped to :category
  # * delay - Mapped to :delay_for
  # * link - ignored
  # * txt - First line of text mapped to :name
  # * sms - ignored
  def self.create_notification(*args)
    values = args.extract_options!
    using = { :delay_for => 0 }.with_indifferent_access.merge(values)
    using[:category] ||= args[1] # type
    using[:delay_for] ||= args[2] # delay
    # 'txt' is the legacy message body. Pull name from first line.
    if args[4].present?
       # txt
      split_txt = args[4].strip.split("\n").map { |line| line.strip }
      using[:name] ||= split_txt[0]
    end
    raise 'Name is required' unless using[:name]
    n = Notification.where(name: using[:name]).first_or_initialize
    begin
      n.update_attributes(:delay_for => using[:delay_for], :category => using[:category])
    rescue => e
      if n.new_record?
        raise "New notification '#{using[:name]}' creation failed. Message: #{e.message}"
      else
        puts "#{name} failed to update"
      end
    end
    n
  end
end
