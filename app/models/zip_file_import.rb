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

class ZipFileImport < Tableless
  attr_accessor :zip_file, :context, :folder_id, :batch_id
  attr_reader :unzip_attachment, :root_directory, :unzip_attachment
  attr_accessible :zip_file, :context, :folder_id, :batch_id

  validates_presence_of :zip_file, :context, :folder_id
  validates_each :zip_file do |record, attr, value|
    record.errors.add attr, 'Must Upload A file' unless record.zip_file.class == Tempfile
    record.errors.add attr, 'The file must be a valid .zip archive' unless record.zip_file.respond_to?(:content_type) && record.zip_file.content_type.to_s.strip.match(/application\/(x-)?zip/)
  end

  def process!
    return false unless valid?
    @root_directory = context.folders.find(folder_id)
    begin
      @unzip_attachment = UnzipAttachment.process(
        :batch_id => batch_id,
        :course => context,
        :root_directory => @root_directory,
        :filename => zip_file.path
      )
    rescue => e
      @error = ErrorReport.create(:backtrace => e.backtrace, :message => e.to_s)
      self.errors.add :zip_file, "Unexpected Error (#{@error.id}) while processing zipped files"
      return false
    end
  end
end
