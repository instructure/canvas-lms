require 'nokogiri'

module Qti
  def self.qti_enabled?
    if plugin = Canvas::Plugin.find(:qti_exporter)
      return plugin.settings[:enabled].to_s == 'true'
    end
    false
  end
end

require 'canvas/migration'
require 'qti_exporter/flavors'
require 'qti_exporter/qti'
require 'qti_exporter/qti_plugin_validator'
require 'qti_exporter/qti_exporter'
require 'workers/qti_worker'
require 'qti_exporter/assessment_item_converter'
require 'qti_exporter/choice_interaction'
require 'qti_exporter/associate_interaction'
require 'qti_exporter/extended_text_interaction'
require 'qti_exporter/assessment_test_converter'
require 'qti_exporter/order_interaction'
require 'qti_exporter/calculated_interaction'
require 'qti_exporter/numeric_interaction'
require 'qti_exporter/fill_in_the_blank'
require 'qti_exporter/question_type_educated_guesser'
