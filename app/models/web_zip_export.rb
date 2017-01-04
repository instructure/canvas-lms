class WebZipExport < EpubExport
  include CC::Exporter::WebZip::Exportable

  def export
    MustViewModuleProgressor.new(user, course).make_progress
    super
  end

  def generate
    job_progress.update_attribute(:completion, PERCENTAGE_COMPLETE[:generating])
    update_attribute(:workflow_state, 'generating')
    convert_to_offline_web_zip
  end
  handle_asynchronously :generate, priority: Delayed::LOW_PRIORITY, max_attempts: 1

  # WebZip Exportable overrides
  def content_cartridge
    self.content_export.attachment
  end

  def convert_to_offline_web_zip
    begin
      set_locale
      file_path = super
      I18n.locale = :en

      create_attachment_from_path!(file_path)
    rescue => e
      mark_as_failed
      raise e
    end

    mark_as_generated
    cleanup_file_path!(file_path)
  end
  handle_asynchronously :convert_to_offline_web_zip, priority: Delayed::LOW_PRIORITY, max_attempts: 1
end
