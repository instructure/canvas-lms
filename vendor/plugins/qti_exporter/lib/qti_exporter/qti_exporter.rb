require_dependency 'qti_exporter/respondus_settings'

module Qti
class QtiExporter < Canvas::Migration::Migrator

  MANIFEST_FILE = "imsmanifest.xml"
  QTI_2_1_URL = 'http://www.imsglobal.org/xsd/imsqti_v2p1'
  QTI_2_0_URL = 'http://www.imsglobal.org/xsd/imsqti_v2p0'
  QTI_2_0_ITEM_URL = 'http://www.imsglobal.org/xsd/imsqti_item_v2p0'
  QTI_2_1_ITEM_URL = 'http://www.imsglobal.org/xsd/imsqti_item_v2p1'
  QTI_2_REGEX = %r{http://www.imsglobal.org/xsd/(?:imsqti_v2p0|imsqti_item_v2p0|imsqti_v2p1|imsqti_item_v2p1)}
  IMS_MD = "http://www.imsglobal.org/xsd/imsmd_v1p2"
  QTI_2_OUTPUT_PATH = "qti_2_1"

  def initialize(settings)
    super(settings, 'qti')
    @questions = {}
    @quizzes = {}
    @files = {}
    @converted = false
    @dest_dir_2_1 = nil
  end

  def export
    unzip_archive

    if QtiExporter.is_qti_2(File.join(@unzipped_file_path, MANIFEST_FILE))
      @dest_dir_2_1 = @unzipped_file_path
      @converted = true
    else
      run_qti_converter
    end

    @course[:assessment_questions] = convert_questions
    @course[:assessments] = convert_assessments(@course[:assessment_questions][:assessment_questions])
    @course[:file_map] = convert_files

    if settings[:apply_respondus_settings_file]
      apply_respondus_settings
    end

    save_to_file
    delete_unzipped_archive
    @course
  end

  def self.is_qti_2(manifest_path)
    if File.exists?(manifest_path)
      File.open(manifest_path) do |io|
        io.each { |line| return true if line =~ QTI_2_REGEX }
      end
    end
    false
  end

  def run_qti_converter
    # convert to 2.1
    @dest_dir_2_1 = File.join(@unzipped_file_path, QTI_2_OUTPUT_PATH)
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

  def convert_questions
    raise "The QTI must be converted to 2.1 before converting to JSON" unless @converted
    begin
      manifest_file = File.join(@dest_dir_2_1, MANIFEST_FILE)
      @questions[:assessment_questions] = Qti.convert_questions(manifest_file)
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
      @quizzes[:assessments] = Qti.convert_assessments(manifest_file, :converted_questions => questions)
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
        @files[attachment] = {
          'migration_id' => "#{@quizzes[:assessments].first.try(:[], :migration_id)}_#{attachment}",
          'path_name' => attachment,
        }
      end
    rescue => e
      message = "Error processing assessment QTI data: #{$!}: #{$!.backtrace.join("\n")}"
      add_error "qti_assessments", message, @files, e
      @files[:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
    end
    unless @files.empty?
      # move the original archive to all_files.zip and it can be processed
      # during the import to grab attachments
      move_archive_to(File.join(@base_export_dir, Canvas::Migration::MigratorHelper::ALL_FILES_ZIP))
    end
    @files
  end

  def apply_respondus_settings
    settings_path = File.join(@unzipped_file_path, 'settings.xml')
    if File.file?(settings_path)
      doc = Nokogiri::XML(open(settings_path))
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
