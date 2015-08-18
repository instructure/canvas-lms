module AccountServices
  def self.allowable_services
    {
        :google_docs => {
            :name => I18n.t("Google Docs"),
            :description => "",
            :expose_to_ui => :service,
            :expose_to_ui_proc => proc { !!GoogleDocs::Connection.config }
        },
        :google_drive => {
            :name => I18n.t("Google Drive"),
            :description => "",
            :expose_to_ui => false
        },
        :google_docs_previews => {
            :name => I18n.t("Google Docs Preview"),
            :description => "",
            :expose_to_ui => :service
        },
        :skype => {
            :name => I18n.t("Skype"),
            :description => "",
            :expose_to_ui => :service
        },
        :linked_in => {
            :name => I18n.t("LinkedIn"),
            :description => "",
            :expose_to_ui => :service,
            :expose_to_ui_proc => proc { !!LinkedIn::Connection.config }
        },
        :twitter => {
            :name => I18n.t("Twitter"),
            :description => "",
            :expose_to_ui => :service,
            :expose_to_ui_proc => proc { !!Twitter::Connection.config }
        },
        :yo => {
            :name => I18n.t("Yo"),
            :description => "",
            :expose_to_ui => :service,
            :expose_to_ui_proc => proc { !!Canvas::Plugin.find(:yo).try(:enabled?) }
        },
        :delicious => {
            :name => I18n.t("Delicious"),
            :description => "",
            :expose_to_ui => :service
        },
        :diigo => {
            :name => I18n.t("Diigo"),
            :description => "",
            :expose_to_ui => :service,
            :expose_to_ui_proc => proc { !!Diigo::Connection.config }
        },
        # TODO: move avatars to :settings hash, it makes more sense there
        # In the meantime, we leave it as a service but expose it in the
        # "Features" (settings) portion of the account admin UI
        :avatars => {
            :name => I18n.t("User Avatars"),
            :description => "",
            :default => false,
            :expose_to_ui => :setting
        },
        :account_survey_notifications => {
            :name => I18n.t("Account Surveys"),
            :description => "",
            :default => false,
            :expose_to_ui => :setting,
            :expose_to_ui_proc => proc do |user, account|
              user && account && account.grants_right?(user, :manage_site_settings)
            end
        },
    }.merge(@plugin_services || {}).freeze
  end

  def self.register_service(service_name, info_hash)
    @plugin_services ||= {}
    @plugin_services[service_name.to_sym] = info_hash.freeze
  end

  def self.default_allowable_services
    self.allowable_services.reject {|_, info| info[:default] == false }
  end
end
