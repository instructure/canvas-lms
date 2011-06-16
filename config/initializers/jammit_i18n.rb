Jammit.module_eval do
  class << self
    I18N_OUTPUT_DIR = 'javascripts/translations'

    def load_configuration_with_i18n_js(config_path, soft=false)
      load_configuration_without_i18n_js(config_path, soft)
      include_js_locale_files
      self
    end
    alias_method_chain :load_configuration, :i18n_js

    def include_js_locale_files
      configuration[:javascripts].each do |name, files|
        translation_file = File.join('public', I18N_OUTPUT_DIR, "#{name}.js")
        files << translation_file if File.exist?(translation_file)
        if name == :common
          files << generate_core_defaults
        end
      end
    end

    def generate_core_defaults
      output_dir = File.join(Jammit::PUBLIC_ROOT, I18N_OUTPUT_DIR)
      FileUtils.mkdir_p(output_dir) unless File.exists?(output_dir)

      filename = "_core.js"
      File.open(File.join(output_dir, filename), "w+") do |f|
        f << <<-BUNDLE
var I18n = I18n || {};
(function($) {
  var translations = #{load_core_defaults.to_json};
  if (I18n.translations) {
    $.extend(true, I18n.translations, translations);
  } else {
    I18n.translations = translations;
  }
})(jQuery);
        BUNDLE
      end
      File.join('public', I18N_OUTPUT_DIR, filename)
    end

    def load_core_defaults
      core_translations = {}
      ::I18n.backend.available_locales
      default_translations = ::I18n.backend.send(:translations)[::I18n.default_locale]
      [:number, :time, :date, :datetime].each do |key|
        core_translations[key] = default_translations[key]
      end
      {::I18n.default_locale => core_translations}
    end
  end
end

Jammit.reload!
