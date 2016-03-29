class CreateK12Theme < ActiveRecord::Migration
  tag :predeploy

  NAME = "K12 Theme"

  def up
    variables = {
      "ic-brand-primary"=>"#E66135",
      "ic-brand-button--primary-bgd"=>"#4A90E2",
      "ic-link-color"=>"#4A90E2",
      "ic-brand-global-nav-bgd"=>"#4A90E2",
      "ic-brand-global-nav-logo-bgd"=>"#3B73B4"
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
