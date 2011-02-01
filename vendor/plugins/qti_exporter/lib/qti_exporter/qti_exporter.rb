module Qti
class QtiExporter < Canvas::Migrator

  MANIFEST_FILE = "imsmanifest.xml"
  QTI_2_1_URL = 'http://www.imsglobal.org/xsd/imsqti_v2p1'
  QTI_2_0_URL = 'http://www.imsglobal.org/xsd/imsqti_v2p0'

  def initialize(settings)
    super(settings, 'qti')
    @questions = {}
    @quizzes = {}
    @converted = false
    @dest_dir_2_1 = nil
    @id_prepender = settings[:id_prepender]
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
    @course[:assessments] = convert_assessments

    if @id_prepender
      @course[:assessment_questions][:assessment_questions].each do |q|
        q[:migration_id] = "#{@id_prepender}_#{q[:migration_id]}"
      end
      @course[:assessments][:assessments].each do |a|
        a[:migration_id] = "#{@id_prepender}_#{a[:migration_id]}"
        a[:questions].each do |q|
          if q[:question_type] == "question_reference"
            q[:migration_id] = "#{@id_prepender}_#{q[:migration_id]}"
          elsif q[:question_type] == "question_group"
            q[:questions].each do |gq|
              gq[:migration_id] = "#{@id_prepender}_#{gq[:migration_id]}"
            end
          end
        end
      end
    end

    save_to_file
    delete_unzipped_archive
    @course
  end

  def self.is_qti_2(manifest_path)
    if File.exists?(manifest_path)
      File.open(manifest_path) do |io|
        io.each { |line| return true if line.include?(QTI_2_1_URL) || line.include?(QTI_2_0_URL) }
      end
    end
    false
  end

  def run_qti_converter
    # convert to 2.1
    @dest_dir_2_1 = File.join(@unzipped_file_path, "qti_2_1")
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

  def convert_assessments
    raise "The QTI must be converted to 2.1 before converting to JSON" unless @converted
    begin
      manifest_file = File.join(@dest_dir_2_1, MANIFEST_FILE)
      @quizzes[:assessments] = Qti.convert_assessments(manifest_file, false)
    rescue => e
      message = "Error processing assessment QTI data: #{$!}: #{$!.backtrace.join("\n")}"
      add_error "qti_assessments", message, @questions, e
      @quizzes[:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
    end
    @quizzes
  end

end
end