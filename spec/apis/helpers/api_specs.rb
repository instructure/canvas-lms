shared_examples_for "API tests" do

  # Assert the provided JSON hash complies with the JSON-API format specification.
  #
  # The following tests will be carried out:
  #
  #   - all resource entries must be wrapped inside arrays, even if the set
  #     includes only a single resource entry
  #   - when associations are present, a "meta" entry should be present and
  #     it should indicate the primary set in the "primaryCollection" key
  #
  # @param [Hash] json
  #   The JSON construct to test.
  #
  # @param [String] primary_set
  #   Name of the primary resource the construct represents, i.e, the model
  #   the API endpoint represents, like 'quiz', 'assignment', or 'submission'.
  #
  # @param [Array<String>] associations
  #   An optional set of associated resources that should be included with
  #   the primary resource (e.g, a user, an assignment, a submission, etc.).
  #
  # @example Testing a Quiz API model:
  #   test_jsonapi_compliance!(json, 'quiz')
  #
  # @example Testing a Quiz API model with its assignment included:
  #   test_jsonapi_compliance!(json, 'quiz', [ 'assignment' ])
  #
  # @example A complying construct of a Quiz Submission with its Assignment:
  #
  #     {
  #       "quiz_submissions": [{
  #         "id": 10,
  #         "assignment_id": 5
  #       }],
  #       "assignments": [{
  #         "id": 5
  #       }],
  #       "meta": {
  #         "primaryCollection": "quiz_submissions"
  #       }
  #     }
  #
  def assert_jsonapi_compliance!(json, primary_set, associations = [])
    required_keys =  [ primary_set ]

    if associations.any?
      required_keys.concat associations.map { |s| s.pluralize }
      required_keys << 'meta'
    end

    json.size.should == required_keys.size

    required_keys.each do |key|
      json.has_key?(key).should be_true
      json[key].is_a?(Array).should be_true unless key == 'meta'
    end

    if associations.any?
      json['meta']['primaryCollection'].should == primary_set
    end
  end
end