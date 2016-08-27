module Canvas::Migration
  class Archive
    attr_reader :warnings

    def initialize(settings={})
      @settings = settings
      @warnings = []
    end

    def file
      @file ||= @settings[:archive_file] || download_archive
    end

    def zip_file
      @zip_file ||= Zip::File.open(file) rescue false
    end

    def read(entry)
      if zip_file
        zip_file.read(entry)
      else
        unzip_archive
        path = File.join(self.unzipped_file_path, entry)
        File.exist?(path) && File.read(path)
      end
    end

    def find_entry(entry)
      if zip_file
        zip_file.find_entry(entry)
      else
        # if it's not an actual zip file
        # just extract the package (or try to) and look for the file
        unzip_archive
        File.exist?(File.join(self.unzipped_file_path, entry))
      end
    end

    def download_archive
      config = ConfigFile.load('external_migration') || {}
      if @settings[:export_archive_path]
        File.open(@settings[:export_archive_path], 'rb')
      elsif @settings[:course_archive_download_url].present?
        _, uri = CanvasHttp.validate_url(@settings[:course_archive_download_url])
        CanvasHttp.get(@settings[:course_archive_download_url]) do |http_response|
          raise CanvasHttp::InvalidResponseCodeError.new(http_response.code.to_i) unless http_response.code.to_i == 200
          tmpfile = CanvasHttp.tempfile_for_uri(uri)
          http_response.read_body(tmpfile)
          tmpfile.rewind
          return tmpfile
        end
      elsif @settings[:attachment_id]
        att = Attachment.find(@settings[:attachment_id])
        att.open(:temp_folder => config[:data_folder], :need_local_file => true)
      else
        raise "No migration file found"
      end
    end

    def path
      file.path
    end

    def unzipped_file_path
      unless @unzipped_file_path
        config = ConfigFile.load('external_migration') || {}
        @unzipped_file_path = Dir.mktmpdir(nil, config[:data_folder].presence)
      end
      @unzipped_file_path
    end

    def get_converter
      Canvas::Migration::PackageIdentifier.new(self).get_converter
    end

    def unzip_archive
      return if @unzipped
      Rails.logger.debug "Extracting #{path} to #{unzipped_file_path}"
      warnings = CanvasUnzip.extract_archive(path, unzipped_file_path)
      @unzipped = true
      unless warnings.empty?
        diagnostic_text = ''
        warnings.each do |tag, files|
          diagnostic_text += tag.to_s + ': ' + files.join(', ') + "\n"
        end
        Rails.logger.debug "CanvasUnzip returned warnings: " + diagnostic_text
        add_warning(I18n.t('canvas.migration.warning.unzip_warning', 'The content package unzipped successfully, but with a warning'), diagnostic_text)
      end
      return true
    end

    def delete_unzipped_archive
      if @unzipped_file_path && File.directory?(@unzipped_file_path)
        FileUtils::rm_rf(@unzipped_file_path)
      end
    end

    # If the file is a zip file, unzip it, if it's an xml file, copy
    # it into the directory with the given file name
    def prepare_cartridge_file(file_name='imsmanifest.xml')
      if self.path.ends_with?('xml')
        FileUtils::cp(self.path, File.join(self.unzipped_file_path, file_name))
      else
        unzip_archive
      end
    end

    def delete_unzipped_file
      if File.exist?(self.unzipped_file_path)
        FileUtils::rm_rf(self.unzipped_file_path)
      end
    end

    def add_warning(warning)
      @warnings << warning
    end
  end
end