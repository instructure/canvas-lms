VCR.configure do |c|
  c.hook_into :webmock
  # c.ignore_hosts 'example.com'
  c.configure_rspec_metadata!
  c.preserve_exact_body_bytes { true }
  c.ignore_localhost                        = true
  c.cassette_library_dir                    = 'spec/support/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
  c.default_cassette_options                = {
    record: ENV.fetch('VCR', 'once').to_sym,
    allow_playback_repeats: false,
    match_requests_on: [:method, :uri, :query]
  }
  c.debug_logger                            = File.open(Rails.root.join('log/vcr.log'), 'w')
end
