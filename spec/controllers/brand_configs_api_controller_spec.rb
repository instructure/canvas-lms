require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BrandConfigsApiController do
  describe '#show' do

    it "should redirect to the default when nothing is set" do
      get :show
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{BrandableCSS.public_default_json_path}")
    end

    it "should redirect to the one for @domain_root_account's brand config if set" do
      Account.default.enable_feature!(:use_new_styles)
      brand_config = Account.default.create_brand_config!(variables: {"ic-brand-primary" => "#321"})
      get :show
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{brand_config.public_json_path}")
    end
  end
end
