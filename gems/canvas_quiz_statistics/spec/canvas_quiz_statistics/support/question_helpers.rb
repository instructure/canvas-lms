require 'json'

module QuestionHelpers
  FixturePath = File.join(File.dirname(__FILE__), 'fixtures')

  # Loads a question data fixture from support/fixtures/*_data.json, just pass
  # it the type of the question, e.g:
  #
  #   @question_data = question_data_fixture('multiple_choice_question')
  #   # now you have a valid question data to analyze.
  #
  #   # and you can munge and customize it:
  #   @question_data[:answers].each { |a| ... }
  #
  # @return [Hash]
  def self.fixture(question_type)
    path = File.join(FixturePath, "#{question_type}_data.json")

    unless File.exist?(path)
      raise '' <<
        "Missing question data fixture for question of type #{question_type}" <<
        ", expected file to be located at #{path}"
    end

    JSON.parse(File.read(path)).with_indifferent_access
  end
end