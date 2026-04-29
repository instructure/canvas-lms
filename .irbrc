# frozen_string_literal: true

IRB.conf[:USE_AUTOCOMPLETE] = false

# Load personal IRB configuration if it exists
local_irbrc = File.join(File.dirname(__FILE__), ".irbrc.local")
load local_irbrc if File.exist?(local_irbrc)
