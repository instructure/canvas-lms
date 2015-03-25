module Qti
class Converter < Canvas::Migration::Migrator

  include CC::Importer::Canvas::QuizMetadataConverter

  MANIFEST_FILE = "imsmanifest.xml"
  QTI_2_1_URL = 'http://www.imsglobal.org/xsd/imsqti_v2p1'
  QTI_2_0_URL = 'http://www.imsglobal.org/xsd/imsqti_v2p0'
  QTI_2_0_ITEM_URL = 'http://www.imsglobal.org/xsd/imsqti_item_v2p0'
  QTI_2_1_ITEM_URL = 'http://www.imsglobal.org/xsd/imsqti_item_v2p1'
  QTI_2_NAMESPACES = %w[
    http://www.imsglobal.org/xsd/imsqti_v2p0
    http://www.imsglobal.org/xsd/imsqti_v2p1
    http://www.imsglobal.org/xsd/qti/qtiv2p0
    http://www.imsglobal.org/xsd/qti/qtiv2p1
  ]
  IMS_MD = "http://www.imsglobal.org/xsd/imsmd_v1p2"
  QTI_2_OUTPUT_PATH = "qti_2_1"

  def initialize(settings)
    super(settings, 'qti')
    @questions = {}
    @quizzes = {}
    @converted = false
    @dest_dir_2_1 = nil
    @course[:hidden_folders] = [MigratorHelper::QUIZ_FILE_DIRECTORY]
    @flavor = settings[:flavor]
  end

  def export
    unzip_archive

    if Converter.is_qti_2(File.join(@unzipped_file_path, MANIFEST_FILE))
      @dest_dir_2_1 = @unzipped_file_path
      @converted = true
    else
      run_qti_converter
    end

    convert_files
    path_map = @course[:file_map].values.inject({}){|h, v| h[v[:path_name]] = v[:migration_id]; h }
    @course[:assessment_questions] = convert_questions(:file_path_map => path_map, :flavor => @flavor)
    @course[:assessments] = convert_assessments(@course[:assessment_questions][:assessment_questions])

    original_manifest_path = File.join(@unzipped_file_path, MANIFEST_FILE)
    if File.exists?(original_manifest_path)
      @manifest = Nokogiri::XML(File.open(original_manifest_path))
      post_process_assessments # bring in canvas metadata if available
    end

    @course[:files_import_root_path] = unique_quiz_dir

    if settings[:apply_respondus_settings_file]
      apply_respondus_settings
    end

    @course['all_files_zip'] = package_course_files(@dest_dir_2_1)
    save_to_file
    delete_unzipped_archive
    @course
  end

  def self.is_qti_2(manifest_path)
    if File.exists?(manifest_path)
      xml = Nokogiri::XML(File.open(manifest_path))
      if xml.namespaces.values.any? { |v| QTI_2_NAMESPACES.any?{|ns| v.to_s.start_with?(ns)} }
        return true
      elsif (xml.at_css('metadata schema') ? xml.at_css('metadata schema').text : '') =~ /QTIv2\./i
        return true
      end
    end
    false
  end

  def run_qti_converter
    # convert to 2.1
    @dest_dir_2_1 = Dir.mktmpdir(QTI_2_OUTPUT_PATH)
    command = Qti.get_conversion_command(@dest_dir_2_1, @unzipped_file_path)
    logger.debug "Running migration command: #{command}"
    python_std_out = `#{command}`

    if $?.exitstatus == 0
      @converted = true
    else
      make_export_dir #so the error file can be written
      qti_error_file = File.join(@base_export_dir, "qti_conversion_error.log")
      message = "Couldn't convert QTI 1.2 to 2.1, see error log: #{qti_error_file}"
      logger.error message
      File.open(qti_error_file, 'w') { |f| f << python_std_out }
      raise message
    end
  end

  def convert_questions(opts={})
    raise "The QTI must be converted to 2.1 before converting to JSON" unless @converted
    begin
      manifest_file = File.join(@dest_dir_2_1, MANIFEST_FILE)
      @questions[:assessment_questions] = Qti.convert_questions(manifest_file, opts)
    rescue => e
      message = "Error processing question QTI data: #{$!}: #{$!.backtrace.join("\n")}"
      add_error "qti_questions", message, @questions, e
      @questions[:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
    end
    @questions
  end

  def convert_assessments(questions = [])
    raise "The QTI must be converted to 2.1 before converting to JSON" unless @converted
    begin
      manifest_file = File.join(@dest_dir_2_1, MANIFEST_FILE)
      @quizzes[:assessments] = Qti.convert_assessments(manifest_file, @settings.merge({:converted_questions => questions}))
    rescue => e
      message = "Error processing assessment QTI data: #{$!}: #{$!.backtrace.join("\n")}"
      add_error "qti_assessments", message, @questions, e
      @quizzes[:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
    end
    @quizzes
  end

  def convert_files
    begin
      manifest_file = File.join(@dest_dir_2_1, MANIFEST_FILE)
      Qti.convert_files(manifest_file).each do |attachment|
        mig_id = Digest::MD5.hexdigest(attachment)
        mig_id = ::Canvas::Migration::MigratorHelper.prepend_id(mig_id, id_prepender)
        @course[:file_map][mig_id] = {
          :migration_id => mig_id,
          :path_name => attachment,
        }
      end
    rescue => e
      message = "Error processing assessment QTI data: #{$!}: #{$!.backtrace.join("\n")}"
      add_error "qti_assessments", message, @course[:file_map], e
      @course[:file_map][:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
    end
    @course[:file_map]
  end

  def apply_respondus_settings
    settings_path = File.join(@unzipped_file_path, 'settings.xml')
    if File.file?(settings_path)
      doc = Nokogiri::XML(File.open(settings_path))
    end
    if doc
      respondus_settings = Qti::RespondusSettings.new(doc)
      @course[:assessments][:assessments].each do |assessment|
        respondus_settings.apply(assessment)
      end
    end
  end

end
end
