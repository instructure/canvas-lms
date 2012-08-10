module Moodle
  class Converter < Canvas::Migration::Migrator
    def initialize(settings)
      super(settings, "moodle")
    end

    def export(to_export = Canvas::Migration::Migrator::SCRAPE_ALL_HASH)
      migrator = Moodle2CC::Migrator.new @archive_file.path, @unzipped_file_path, 'format' => 'canvas', 'logger' => self
      migrator.migrate

      @settings[:archive_file] = File.open(migrator.imscc_path)
      cc_converter = CC::Importer::Canvas::Converter.new(@settings)
      cc_converter.export
      @course = cc_converter.course
    ensure
      FileUtils.rm migrator.imscc_path if migrator && File.exists?(migrator.imscc_path)
    end

  end
end
