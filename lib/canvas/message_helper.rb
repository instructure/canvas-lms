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
    File.join(RAILS_ROOT, 'app', 'messages', filename)
  end

  def self.add_message_path(path)
    if File.exists?(path) && File.directory?(path)
      @message_paths ||= []
      @message_paths << path
    end
  end

  def self.find_message_path(filename)
    path = nil
    if @message_paths
      @message_paths.each do |mp|
        test_path = File.join(mp, filename)
        if File.exists?(test_path)
          path = test_path
          break
        end
      end
    end
    path || default_message_path(filename)
  end

  def self.create_notification(context, type, delay, link, txt, sms="")
    # Ignoring context for now.
    split_txt = txt.strip.split("\n").map { |line| line.strip }
    name = split_txt[0]
    subject = split_txt[2]
    n = Notification.find_or_initialize_by_name(name)
    begin
      n.update_attributes(:subject => subject, :main_link => link[0..254], :delay_for => delay, :category => type)
    rescue => e
      if n.new_record?
        raise "New notification creation failed"
      else
        puts "#{name} failed to update"
      end
    end
    others = Notification.find_all_by_name_and_category(name, type)
    others.each do |other|
      other.destroy unless other == n
    end
    n
  end
end
