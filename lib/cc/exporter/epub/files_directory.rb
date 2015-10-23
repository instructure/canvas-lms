module CC::Exporter::Epub
  class FilesDirectory
    def initialize(files)
      @files = files
    end
    attr_reader :files

    def add_files
      files.each do |file_data|
        File.open(file_data[:path_to_file]) do |file|
          zip_file.add(file_data[:local_path], file)
        end
      end
    end

    def create
      return nil unless files.any?

      begin
        add_files
      ensure
        zip_file.close if zip_file
      end

      zip_file.to_s
    end

    def export_directory
      unless @_export_directory
        path = File.join(Dir.tmpdir, Time.zone.now.strftime("%s"))
        @_export_directory = FileUtils.mkdir_p(path)
      end

      @_export_directory.first
    end

    def filename
      @_filename ||= "#{SecureRandom.uuid}.zip"
    end

    def zip_file
      @_zip_file ||= Zip::File.new(
        File.join(export_directory, filename),
        Zip::File::CREATE
      )
    end
  end
end
