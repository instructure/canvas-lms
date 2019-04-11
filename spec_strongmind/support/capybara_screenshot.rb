
Capybara::Screenshot.prune_strategy      = { keep: 10 }
Capybara::Screenshot.autosave_on_failure = (ENV['CI'] || ENV['HEADLESS']) ? true : false
Capybara::Screenshot.append_timestamp    = true
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  "#{ 'TRAVISCI-' if ENV['CI'] }spec-fail-screenshot_#{example.description.gsub(/[^[:alpha:]]/, '-').gsub(/^.*\/spec\//,'')}"
end

Capybara::Screenshot.s3_configuration = {
  s3_client_credentials: {
    access_key_id: ENV['S3_ACCESS_KEY_ID'],
    secret_access_key: ENV['S3_ACCESS_KEY'],
    region: ENV['AWS_REGION']
  },
  bucket_name: "canvas-lms-feature-spec-failure-screenshots"
}

if ENV['CI']
  Capybara::Screenshot::RSpec.add_link_to_screenshot_for_failed_examples = false
end
