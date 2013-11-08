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
      add_question_warnings

      File.open(@course[:full_export_file_path], 'w') { |file| file << @course.to_json}
      @course
    ensure
      FileUtils.rm migrator.imscc_path if migrator && File.exists?(migrator.imscc_path)
    end

    def add_question_warnings
      return unless @course[:assessment_questions] && @course[:assessment_questions][:assessment_questions]

      @course[:assessment_questions][:assessment_questions].each do |q_hash|
        if q_hash['question_type'] == 'multiple_dropdowns_question'
          q_hash['import_warnings'] ||= []
          q_hash['import_warnings'] << I18n.t(:moodle_dropdown_warning_title, 'Multiple Dropdowns question may have been imported incorrectly')
        end
      end
    end

  end
end
