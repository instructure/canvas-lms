class WebZipExport < EpubExport
  include CC::Exporter::WebZip::Exportable

  # WebZipExport and the case of the mysteryous synchronous kwarg:
  #
  # We've had to add the synchronous flag here to satisify the API established
  # by the prepended module from inst-jobs, the actual method definition that
  # gets called by super here is defined by inst-job in a module called
  # `EpubExport::DelayedMethods`, which is prepended to the parent class here
  # but ends up being later in the lookup chain for this class.
  def export(synchronous: false)
    module_progressor = MustViewModuleProgressor.new(user, course)
    Rails.cache.write(cache_key, module_progressor.current_progress, expires_in: 4.hours)
    module_progressor.make_progress
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
      file_path = super(cache_key)
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

  def cache_key
    "web_zip_export_user_progress_#{global_id}"
  end
end
