# frozen_string_literal: true

# we don't want zeitwerk to try to eager_load some
# "Version" constant, as it won't exist
Rails.autoloaders.main.ignore("#{__dir__}/../../lib/qti_exporter/version.rb")
