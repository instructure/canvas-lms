#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class BrandConfigsController < ApplicationController

  include Api::V1::Progress
  include Api::V1::Account

  before_action :require_account_context
  before_action :require_user
  before_action :require_account_management
  before_action :require_account_branding, except: [:destroy]
  before_action { |c| c.active_tab = "brand_configs" }

  def index
    add_crumb t('Themes')
    @page_title = join_title(t('Themes'), @account.name)
    css_bundle :brand_config_index
    js_bundle :brand_configs_index

    base_brand_config = @account.parent_account.try(:effective_brand_config)
    base_brand_config ||= BrandConfig.k12_config if k12?

    js_env brandConfigStuff: {
      baseBrandableVariables: BrandableCSS.all_brand_variable_values(base_brand_config),
      brandableVariableDefaults: BrandableCSS.variables_map,
      accountID: @account.id.to_s,
      sharedBrandConfigs: visible_shared_brand_configs.as_json(include_root: false, include: 'brand_config'),
      activeBrandConfig: active_brand_config(ignore_parents: true).as_json(include_root: false)
    }
    render html: '', layout: true
  end

  def new
    @page_title = join_title(t('Theme Editor'), @account.name)
    css_bundle :common, :theme_editor
    js_bundle :theme_editor
    brand_config = active_brand_config(ignore_parents: true) || BrandConfig.new

    js_env brandConfig: brand_config.as_json(include_root: false),
           hasUnsavedChanges: session.key?(:brand_config_md5),
           variableSchema: default_schema,
           allowGlobalIncludes: @account.allow_global_includes?,
           account_id: @account.id
    render html: '', layout: 'layouts/bare'
  end

  def show
    # this is the controller action for the preview in the theme editor
  end

  def default_schema
    parent_config = @account.first_parent_brand_config || BrandConfig.new
    variables = parent_config.effective_variables
    overridden_schema = duped_brandable_vars
    overridden_schema.each do |group|
      group["variables"].each do |var|
        if variables.keys.include?(var["variable_name"])
          var["default"] = variables[var["variable_name"]]
        end
      end
    end
    overridden_schema
  end
  private :default_schema

  def duped_brandable_vars
    BrandableCSS::BRANDABLE_VARIABLES.map do |group|
      new_group = group.deep_dup
      new_group["group_name"] =  BrandableCSS::GROUP_NAMES[new_group['group_key']].call
      new_group["variables"] = new_group["variables"].map(&:deep_dup)
      new_group["variables"].each do |v|
        v["human_name"] = BrandableCSS::VARIABLE_HUMAN_NAMES[v['variable_name']].call
        if helper_text_proc = BrandableCSS::HELPER_TEXTS[v['variable_name']]
          v["helper_text"] = helper_text_proc.call
        end
      end
      new_group
    end
  end

  # Preview/Create New BrandConfig
  # This is what is called when the user hits 'preview changes' in the theme editor.
  #
  # @argument brand_config[variables] see app/stylesheets/brandable_variables.json for an example of
  #   which variables can be set.
  #
  # If you send your request in mimeType: 'multipart/form-data' then you can have it upload images to use.
  # If the css files for this BrandConfig have not been created yet, it will return a `Progress` object
  # indicating the progress of generating the css and pushing it to the CDN
  # @returns {BrandConfig, Progress}
  def create
    params[:brand_config] ||= {}
    opts = {
      parent_md5: @account.first_parent_brand_config.try(:md5),
      variables: process_variables(params[:brand_config][:variables])
    }
    BrandConfig::OVERRIDE_TYPES.each do |override|
      opts[override] = process_file(params[override])
    end

    brand_config = BrandConfig.for(opts)

    if existing_config(brand_config)
      render json: { brand_config: brand_config.as_json(include_root: false) }
    else
      render json: {
        brand_config: brand_config.as_json(include_root: false),
        progress: progress_json(generate_css(brand_config), @current_user, session)
      }
    end
  end

  # Activiate a given brandConfig for the current users's session.
  # this is what is called after the user pushes "Preview"
  # and after the progress of generating and pushing the css files to the CDN.
  # Or when they pick an existing one from the dropdown of starter themes.
  #
  # @argument brand_config_md5 [String]
  #   If set, will activate this specific brand config as the active one in the session.
  #   If the empty string ('') is passed, will use nothing for this session
  #   (so the user will see the canvas default theme).
  def save_to_user_session
    old_md5 = session.delete(:brand_config_md5)
    session[:brand_config_md5] = if params[:brand_config_md5] == ''
      false
    elsif params[:brand_config_md5]
      BrandConfig.find(params[:brand_config_md5]).md5
    end

    BrandConfig.destroy_if_unused(old_md5) if old_md5 != session[:brand_config_md5]
    redirect_to account_theme_editor_path(@account)
  end

  # After someone is satisfied with the preview of how their session brand config looks,
  # they POST to this action to save it to their account so everyone else sees it.
  def save_to_account
    old_md5 = @account.brand_config_md5
    new_md5 = session.delete(:brand_config_md5).presence
    new_brand_config = new_md5 && BrandConfig.find(new_md5)
    regenerator = BrandConfigRegenerator.new(@account, @current_user, new_brand_config)

    BrandConfig.destroy_if_unused(old_md5)

    render json: {
      subAccountProgresses: regenerator.progresses.map{|p| progress_json(p, @current_user, session)}
    }
  end

  # When you close the theme editor, it will send a DELETE to this action to
  # clear out the session brand_config that you were prevewing.
  def destroy
    old_md5 = session.delete(:brand_config_md5).presence
    BrandConfig.destroy_if_unused(old_md5)
    redirect_to account_brand_configs_path(@account), notice: t('Theme editor changes have been cancelled.')
  end

  def existing_config(config)
    config.default? || !config.new_record?
  end
  private :existing_config

  protected

  def visible_shared_brand_configs
    # things shared in this account, or globally (account_id is nil)
    SharedBrandConfig.where(account_id: [@account.id, nil])
  end

  def require_account_branding
    unless @account.branding_allowed?
      flash[:error] = t "You cannot edit themes on this subaccount."
      redirect_to account_path(@account)
    end
  end

  def process_variables(variables)
    return unless variables
    variables.to_unsafe_h.each_with_object({}) do |(key, value), memo|
      next unless value.present? && (config = BrandableCSS.variables_map[key])
      value = process_file(value) if config['type'] == 'image'
      memo[key] = value
    end
  end

  def process_file(file)
    if file.is_a?(ActionDispatch::Http::UploadedFile)
      upload_file(file)
    else
      file
    end
  end

  def generate_css(brand_config)
    brand_config.save!
    progress = Progress.new(context: @current_user, tag: :brand_config_save_and_sync_to_s3)
    progress.user = @current_user
    progress.reset!
    progress.process_job(brand_config, :save_and_sync_to_s3!, priority: Delayed::HIGH_PRIORITY)
    progress
  end

  def upload_file(file)
    expires_in = 15.years
    attachment = Attachment.new(attachment_options: {
                                  s3_access: 'public-read',
                                  skip_sis: true,
                                  cache_control: "Cache-Control:max-age=#{expires_in.to_i}, public",
                                  expires: expires_in.from_now.httpdate },
                                context: @account)
    attachment.uploaded_data = file
    attachment.save!

    if Attachment.s3_storage?
      attachment.s3_url
    else
      attachment.public_url
    end
  end
end
