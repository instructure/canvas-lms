module Moodle
  class Converter < Canvas::Migration::Migrator
    def initialize(settings)
      super(settings, "moodle")
    end

    def export(to_export = Canvas::Migration::Migrator::SCRAPE_ALL_HASH)
      unzip_archive
      migrator = Moodle2CC::Migrator.new @unzipped_file_path, Dir.mktmpdir, 'format' => 'canvas', 'logger' => self
      migrator.migrate

      if migrator.last_error
        raise migrator.last_error
      end

      @settings[:archive_file] = File.open(migrator.imscc_path)
      @settings.delete(:archive)

      cc_converter = CC::Importer::Canvas::Converter.new(@settings)
      cc_converter.export
      @course = cc_converter.course
      add_question_warnings

      File.open(@course[:full_export_file_path], 'w') { |file| file << @course.to_json}
      @course
    ensure
      FileUtils.rm migrator.imscc_path if migrator && migrator.imscc_path && File.exists?(migrator.imscc_path)
    end

    def add_question_warnings
      return unless @course[:assessment_questions] && @course[:assessment_questions][:assessment_questions]

      warning_map = {}

      @course[:assessment_questions][:assessment_questions].each do |q_hash|
        qb_ident = q_hash['question_bank_id'] || q_hash['question_bank_name'] || :default

        if q_hash['question_type'] == 'multiple_dropdowns_question' || q_hash['question_type'] == 'calculated_question'
          warning_map[qb_ident] ||= {}
          warning_map[qb_ident][q_hash['question_type']] ||= []
          warning_map[qb_ident][q_hash['question_type']] << q_hash
        end
      end

      add_warnings_to_map(warning_map)
    end

    def add_warnings_to_map(warning_map)
      warning_map.values.each do |warnings|
        if hashes = warnings['multiple_dropdowns_question']
          if hashes.count > 2
            q_hash = hashes.first
            q_hash['import_warnings'] ||= []
            q_hash['import_warnings'] << I18n.t(:moodle_dropdown_many_warning_title,
              "There are %{count} Multiple Dropdowns questions in this bank that may have been imported incorrectly",
              :count => hashes.count)
          else
            hashes.each do |q_hash|
              q_hash['import_warnings'] ||= []
              q_hash['import_warnings'] << I18n.t(:moodle_dropdown_warning_title,
                "Multiple Dropdowns question may have been imported incorrectly")
            end
          end
        end

        if hashes = warnings['calculated_question']
          if hashes.count > 2
            q_hash = hashes.first
            q_hash['import_warnings'] ||= []
            q_hash['import_warnings'] << I18n.t(:moodle_formula_many_warning_title,
              "There are %{count} Formula questions in this bank that will need to have their possible answers regenerated",
              :count => hashes.count)
          else
            hashes.each do |q_hash|
              q_hash['import_warnings'] ||= []
              q_hash['import_warnings'] << I18n.t(:moodle_formula_warning_title,
                "Possible answers will need to be regenerated for Formula question")
            end
          end
        end
      end
    end

  end
end
