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

module CC
  class CCExporter
    include TextHelper

    ZIP_DIR = 'zip_dir'
    
    attr_accessor :course, :user, :export_dir, :manifest, :zip_file, :for_course_copy
    delegate :add_error, :add_item_to_export, :to => :@content_export, :allow_nil => true

    def initialize(content_export, opts={})
      @content_export = content_export
      @course = opts[:course] || @content_export.course 
      @user = opts[:user] || @content_export.user
      @export_dir = nil
      @manifest = nil
      @zip_file = nil
      @zip_name = nil
      @logger = Rails.logger
      @migration_config = Setting.from_config('external_migration')
      @migration_config ||= {:keep_after_complete => false}
      @for_course_copy = opts[:for_course_copy]
      @qti_only_export = @content_export && @content_export.qti_export?
    end

    def self.export(content_export, opts={})
      exporter = CCExporter.new(content_export, opts)
      exporter.export
    end

    def export
      begin
        create_export_dir
        create_zip_file
        if @qti_only_export
          @manifest = CC::QTI::QTIManifest.new(self)
        else
          @manifest = Manifest.new(self)
        end
        @manifest.create_document
        @manifest.close
        copy_all_to_zip
        @zip_file.close
        
        if @content_export && File.exists?(@zip_path)
          att = Attachment.new
          att.context = @content_export
          att.user = @content_export.user
          att.uploaded_data = Rack::Test::UploadedFile.new(@zip_path, Attachment.mimetype(@zip_path))
          if att.save
            @content_export.attachment = att
            @content_export.save
          end
        end
      rescue
        add_error(I18n.t('course_exports.errors.course_export', "Error running course export."), $!)
        @logger.error $!
        return false
      ensure
        @zip_file.close if @zip_file
        if !@migration_config[:keep_after_complete] && File.directory?(@export_dir)
          FileUtils::rm_rf(@export_dir)
        end
      end
      true
    end

    def referenced_files
      @manifest ? @manifest.referenced_files : {}
    end
    
    def set_progress(progress)
      @content_export.fast_update_progress(progress) if @content_export  
    end
    
    def errors
      @content_export ? @content_export.error_messages : []
    end
    
    def export_id
      @content_export ? @content_export.id : nil
    end

    def export_object?(obj, asset_type=nil)
      @content_export ? @content_export.export_object?(obj, asset_type) : true
    end

    def export_symbol?(obj)
      @content_export ? @content_export.export_symbol?(obj) : true
    end
    
    private
    
    def copy_all_to_zip
      Dir["#{@export_dir}/**/**"].each do |file|
        file_path = file.sub(@export_dir+'/', '')
        next if file_path.starts_with? ZIP_DIR
        @zip_file.add(file_path, file)
      end
    end

    def create_export_dir
      slug = "common_cartridge_#{@course.id}_user_#{@user.id}"
      if @migration_config[:data_folder]
        folder = @migration_config[:data_folder]
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
      name = CanvasTextHelper.truncate_text(@course.name.to_url, {:max_length => 200, :ellipsis => ''})
      if @qti_only_export
        @zip_name = "#{name}-quiz-export.zip"
      else
        @zip_name = "#{name}-export.#{CCHelper::CC_EXTENSION}"
      end
      FileUtils::mkdir_p File.join(@export_dir, ZIP_DIR)
      @zip_path = File.join(@export_dir, ZIP_DIR, @zip_name)
      @zip_file = Zip::File.new(@zip_path, Zip::File::CREATE)
    end

  end
end
