module CC::Exporter::WebZip
  class ZipPackage < CC::Exporter::Epub::FilesDirectory
    def initialize(exporter)
      @files = exporter.unsupported_files + exporter.cartridge_json[:files]
      @filename_prefix = exporter.filename_prefix
      @viewer_path_prefix = @filename_prefix + '/viewer'
      @path_to_files = nil
      @course_data_filename = 'course-data.js'
      @tempfile_filename = 'empty.txt'
    end
    attr_reader :files
    attr_accessor :file_data

    def add_files
      files.each do |file_data|
        next unless file_data[:exists]
        unless @path_to_files
          match = file_data[:path_to_file].match(%r{.*/web_resources/})
          @path_to_files = match.to_s
        end
        File.open(file_data[:path_to_file]) do |file|
          file_path = file_data[:local_path].sub(%r{^media/}, "#{@viewer_path_prefix}/files/")
          zip_file.add(file_path, file) { add_clone(file_path, file) }
        end
      end
    end

    def create
      return nil unless files.any?

      begin
        add_files
        add_course_data
      ensure
        zip_file&.close
      end

      zip_file.to_s
    end

    def add_course_data
      f = File.new(@course_data_filename, 'w+')

      data = {
        files: create_tree_data
      }

      f.write(data.to_json)

      zip_file.add("#{@viewer_path_prefix}/#{@course_data_filename}", f)
      f.close
    end

    def create_tree_data
      return nil unless @path_to_files

      data = []
      walk(@path_to_files, data)
      data
    end

    def walk(dir, accumulator)
      Dir.foreach(dir) do |file|
        path = File.join(dir, file)
        next if ['.', '..'].include? file
        is_dir = File.directory?(path)
        if is_dir
          next_files = []
          walk(path, next_files)
        end
        accumulator << {
          type: is_dir ? 'folder' : 'file',
          name: file,
          size: is_dir ? nil : File.size(path),
          files: is_dir ? next_files : nil
        }
      end
    end

    def empty_zip_file
      zip_file = Zip::File.new(
        File.join(export_directory, filename),
        Zip::File::CREATE
      )
      f = File.new(@tempfile_filename, "w+")
      zip_file.add(@tempfile_filename, f)
      f.close
      zip_file.close
      zip_file.name
    end

    def cleanup_files
      File.delete(@tempfile_filename) if File.exist?(@tempfile_filename)
      File.delete(@course_data_filename) if File.exist?(@course_data_filename)
    end
  end
end