# frozen_string_literal: true

# this CANVAS_ZEITWERK constant flag is defined in canvas' "application.rb"
# from an env var. It should be temporary,
# and removed once we've fully upgraded to zeitwerk autoloading.
if defined?(CANVAS_ZEITWERK) && CANVAS_ZEITWERK
  # we don't want zeitwerk to try to eager_load some
  # "Version" constant, as it won't exist
  Rails.autoloaders.main.ignore("#{__dir__}/../../lib/qti_exporter/version.rb")
end
