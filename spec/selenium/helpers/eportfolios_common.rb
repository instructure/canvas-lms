require File.expand_path(File.dirname(__FILE__) + '/../common')

def create_eportfolio(is_public = false)
  get "/dashboard/eportfolios"
  f(".add_eportfolio_link").click
  wait_for_animations
  replace_content f("#eportfolio_name"), "student content"
  f("#eportfolio_public").click if is_public
  expect_new_page_load { f("#eportfolio_submit").click }
  eportfolio = Eportfolio.find_by_name("student content")
  expect(eportfolio).to be_valid
  expect(eportfolio.public).to be_truthy if is_public
  expect(f('#content h2')).to include_text(I18n.t('headers.welcome', "Welcome to Your ePortfolio"))
end

def entry_verifier(opts={})
  @eportfolio.eportfolio_entries.count > 0
  entry= @eportfolio.eportfolio_entries.first
  if opts[:section_type]
    expect(entry.content.first[:section_type]).to eq opts[:section_type]
  end

  if opts[:content]
    expect(entry.content.first[:content]).to include_text(opts[:content])
  end
end