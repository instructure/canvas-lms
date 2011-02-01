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

require 'action_controller'
require 'action_controller/test_process.rb'

# Attaches a file generally to another file, using the attachment_fu gateway.
class FileInContext
  class << self
    def queue_files_to_delete(queue=true)
      @queue_files_to_delete = queue
    end
    
    def destroy_queued_files
      Attachment.send_later_if_production(:destroy_files, @queued_files.map(&:id)) if @queued_files && !@queued_files.empty?
    end
    
    def destroy_file(file)
      if @queue_files_to_delete
        @queued_files ||= []
        @queued_files << file
      else
        file.destroy
      end
    end
    
    def attach(context, filename, display_name=nil, folder=nil, explicit_filename=nil)
      display_name ||= File.split(filename).last
      uploaded_data = ActionController::TestUploadedFile.new(filename, Attachment.mimetype(filename))

      # This code will delete any file in the folder that had the same name...
      context.attachments.active.find_all_by_folder_id(folder.id).select{|a| a.filename == explicit_filename }.each{|a| destroy_file(a) } if folder && explicit_filename

      # _and_display_name(
        # folder.id,
        # display_name
      # ).try(:destroy) if folder && folder.id && display_name
      
      @attachment = context.attachments.build(:uploaded_data => uploaded_data, :display_name => display_name, :folder => folder)
      @attachment.write_attribute(:filename, explicit_filename) if explicit_filename
      @attachment.context = context
      @attachment.save!
      @attachment
    end
    
  end
end

