module AttachmentFu
  class Railtie < ::Rails::Railtie
    initializer "attachment_fu.canvas_plugin" do
      ActiveRecord::Base.send(:extend, AttachmentFu::ActMethods)
      AttachmentFu::Railtie.setup_tempfile_path
    end

    def self.setup_tempfile_path
      AttachmentFu.tempfile_path = Rails.root.join('tmp', 'attachment_fu').to_s
      AttachmentFu.tempfile_path = ATTACHMENT_FU_TEMPFILE_PATH if Object.const_defined?(:ATTACHMENT_FU_TEMPFILE_PATH)

      begin
        FileUtils.mkdir_p AttachmentFu.tempfile_path
      rescue Errno::EACCES
        # don't have permission; still let the rest of the app boot
      end
    end
  end
end
