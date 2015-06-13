module GoogleDocs
  class DriveFolder
    attr_reader :name, :folders, :files

    def initialize(name, folders=[], files=[])
      @name = name
      @folders, @files = folders, files
    end

    def add_file(file)
      @files << file
    end

    def add_folder(folder)
      @folders << folder
    end

    def select(&block)
      DriveFolder.new(@name,
                 @folders.map { |f| f.select(&block) }.select { |f| !f.files.empty? },
                 @files.select(&block))
    end

    def map(&block)
      @folders.map { |f| f.map(&block) }.flatten +
        @files.map(&block)
    end

    def flatten
      @folders.flatten + @files
    end

    def to_hash
      {
        :name => @name,
        :folders => @folders.map { |sf| sf.to_hash },
        :files => @files.map { |f| f.to_hash }
      }
    end
  end
end