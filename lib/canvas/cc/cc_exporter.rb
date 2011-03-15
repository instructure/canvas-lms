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
module Canvas::CC
  class CCExporter

    attr_accessor :course, :user, :export_dir, :manifest, :zip_file

    def initialize(course, user, opts={})
      @course = course
      @user = user
      @export_dir = nil
      @manifest = nil
      @zip_file = nil
      @logger = Rails.logger
    end

    def self.export(course, user, opts={})
      exporter = CCExporter.new(course, user, opts)
      exporter.export
    end

    def export
      begin
        create_export_dir
        create_zip_file
        @manifest = Manifest.new(self)
        @manifest.create_document
        @manifest.close
        #copy all folder contents into zip file
        #create attachment from zip file
        #delete directory
      rescue => e
        #todo error handling
        @logger.error e
        #delete directory?
      ensure
        @zip_file.close if @zip_file
      end
    end
    
    private

    def create_export_dir
      slug = "common_cartridge_#{@course.id}_user_#{@user.id}"
      config = Setting.from_config('external_migration')
      if config && config[:data_folder]
        folder = config[:data_folder]
      else
        folder = Dir.tmpdir
      end

      @export_dir = File.join(folder, slug)
      i = 1
      while File.exists?(@export_dir) && File.directory?(@export_dir)
        i += 1
        @export_dir = File.join(folder, "#{slug}_attempt_#{i}")
      end

      FileUtils::mkdir_p @export_dir
      @export_dir
    end

    def create_zip_file
      path = File.join(@export_dir, "#{@course.name.to_url}-export.#{CCHelper::CC_EXTENSION}")
      @zip_file = Zip::ZipFile.new(path, Zip::ZipFile::CREATE)
    end

  end
end