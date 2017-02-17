class CreateMinimalistTheme < ActiveRecord::Migration[4.2]
  tag :predeploy

  NAME = "Minimalist Theme"

  def up
    variables = {
      "ic-brand-primary"=>"#2773e2",
      "ic-brand-button--secondary-bgd"=>"#4d4d4d",
      "ic-link-color"=>"#1d6adb",
      "ic-brand-global-nav-bgd"=>"#f2f2f2",
      "ic-brand-global-nav-ic-icon-svg-fill"=>"#444444",
      "ic-brand-global-nav-menu-item__text-color"=>"#444444",
      "ic-brand-global-nav-avatar-border"=>"#444444",
      "ic-brand-global-nav-logo-bgd"=>"#4d4d4d",
      "ic-brand-watermark-opacity"=>"1",
      "ic-brand-Login-body-bgd-color"=>"#f2f2f2",
      "ic-brand-Login-body-bgd-shadow-color"=>"#f2f2f2",
      "ic-brand-Login-Content-bgd-color"=>"#ffffff",
      "ic-brand-Login-Content-border-color"=>"#efefef",
      "ic-brand-Login-Content-label-text-color"=>"#444444",
      "ic-brand-Login-Content-password-text-color"=>"#444444",
      "ic-brand-Login-Content-button-bgd"=>"#2773e2",
      "ic-brand-Login-footer-link-color"=>"#2773e2",
      "ic-brand-Login-instructure-logo"=>"#aaaaaa"
    }
    bc = BrandConfig.new(variables: variables)
    bc.name = NAME
    bc.share = true
    bc.save!
    bc.save_scss_file!
  end

  def down
    BrandConfig.where(name: NAME).delete_all
  end
end
