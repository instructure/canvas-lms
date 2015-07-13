class BrandConfigsController < ApplicationController
  before_filter :require_user
  before_filter :require_manage_account_settings, except: [:destroy]

  def new
    @page_title = join_title(t('Theme Editor'), @domain_root_account.name)
    css_bundle :common, :theme_editor
    js_bundle :theme_editor
    brand_config = active_brand_config || BrandConfig.new
    js_env brandConfig: brand_config.as_json(include_root: false),
           hasUnsavedChanges: active_brand_config != @domain_root_account.brand_config,
           variableSchema: BrandableCSS::BRANDABLE_VARIABLES,
           sharedBrandConfigs: BrandConfig.select('md5, name').where(share: true).as_json(include_root: false)
    render text: '', layout: 'layouts/bare'
  end

  def create
    old_md5 = session[:brand_config_md5]
    session[:brand_config_md5] = begin
      if params[:brand_config] == ''
        false
      elsif params[:brand_config][:md5]
        BrandConfig.find(params[:brand_config][:md5]).md5
      elsif (variables = params[:brand_config][:variables])
        create_brand_config(variables).md5
      end
    end
    BrandConfig.destroy_if_unused(old_md5)
    redirect_to brand_configs_new_path
  end

  def save_to_account
    old_md5 = @domain_root_account.brand_config_md5
    new_md5 = session.delete(:brand_config_md5).presence
    @domain_root_account.brand_config = new_md5 && BrandConfig.find(new_md5)
    @domain_root_account.save!
    BrandConfig.destroy_if_unused(old_md5)
    redirect_to :back, notice: t('Success! All users on this domain will now see this branding.')
  end

  def destroy
    session.delete(:brand_config_md5)
    BrandConfig.destroy_if_unused(session.delete(:brand_config_md5))
    flash[:notice] = t('Theme editor changes have been cancelled.')
    render json: {success: true}
  end

  protected

  def require_manage_account_settings
    return false unless authorized_action(@domain_root_account,
                                          @current_user,
                                          :manage_account_settings) && use_new_styles?
  end

  def create_brand_config(variables)
    variables_to_save = variables.each_with_object({}) do |(key, value), memo|
      next unless value.present? && (config = BrandableCSS.variables_map[key])
      value = upload_image(value) if config['type'] == 'image' && value.is_a?(ActionDispatch::Http::UploadedFile)
      memo[key] = value
    end
    brand_config = BrandConfig.create!(variables: variables_to_save)
    # TODO, show user progress of this
    brand_config.send_later_if_production(:save_and_sync_to_s3!)
    brand_config
  end


  def upload_image(image)
    attachment = Attachment.create(uploaded_data: image, context: @domain_root_account)
    expires_in = 15.years
    attachment.authenticated_s3_url({
      # this is how long the s3 verifier token will work
      expires: expires_in,
      # these are the http cache headers that will be set on the response
      response_expires: expires_in,
      response_cache_control: "Cache-Control:max-age=#{expires_in}, public"
    })
  end

end
