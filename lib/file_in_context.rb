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

require 'action_controller_test_process'

# Attaches a file generally to another file, using the attachment_fu gateway.
class FileInContext
  class << self

    def queue_files_to_delete(queue=true)
      @queue_files_to_delete = queue
    end
    
    def destroy_queued_files
      if @queued_files && !@queued_files.empty?
        Attachment.send_later_if_production(:destroy_files, @queued_files.map(&:id))
        @queued_files.clear
      end
    end
    
    def destroy_files(files)
      if @queue_files_to_delete
        @queued_files ||= []
        @queued_files += files
      else
        files.each{ |f| f.destroy }
      end
    end
    
    def attach(context, filename, display_name=nil, folder=nil, explicit_filename=nil, allow_rename = false)
      display_name ||= File.split(filename).last
      uploaded_data = Rack::Test::UploadedFile.new(filename, Attachment.mimetype(explicit_filename || filename))

      @attachment = context.attachments.build(:uploaded_data => uploaded_data, :display_name => display_name, :folder => folder)
      @attachment.filename = explicit_filename if explicit_filename
      @attachment.context = context
      @attachment.save!

      destroy_files(@attachment.handle_duplicates(allow_rename ? :rename : :overwrite, :caller_will_destroy => true))

      @attachment
    ensure
      uploaded_data.close if uploaded_data
    end
    
  end
end
