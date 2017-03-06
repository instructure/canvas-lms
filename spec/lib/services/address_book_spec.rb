require_relative "../../spec_helper"
require_dependency "services/address_book"

module Services
  describe AddressBook do
    before do
      @app_host = "address-book"
      @secret = "opensesame"
      allow(Canvas::DynamicSettings).to receive(:find).
        with("address-book").
        and_return({ "app-host" => @app_host, "secret" => Canvas::Security.base64_encode(@secret) })
      @sender = user_model
      @course = course_model
    end

    def expect_request(url_matcher, options={})
      body = options[:body] || { records: [] }
      header_matcher = options[:headers] || anything
      expect(CanvasHttp).to receive(:get).
        with(url_matcher, header_matcher).
        and_return(double(body: body.to_json, code: 200))
    end

    def stub_response(url_matcher, body, options={})
      status = options[:status] || 200
      header_matcher = options[:headers] || anything
      allow(CanvasHttp).to receive(:get).
        with(url_matcher, header_matcher).
        and_return(double(body: body.to_json, code: status))
    end

    let(:example_response) do
      {
        records: [
          { user_id: '10000000000002', cursor: 8, contexts: [
            { 'context_type' => 'course', 'context_id' => '10000000000001', 'roles' => ['TeacherEnrollment'] }
          ]},
          { user_id: '10000000000005', cursor: 12, contexts: [
            { 'context_type' => 'course', 'context_id' => '10000000000002', 'roles' => ['StudentEnrollment'] },
            { 'context_type' => 'group', 'context_id' => '10000000000001', 'roles' => ['Member'] }
          ]}
        ]
      }
    end

    def not_match(*args)
      ::RSpec::Matchers::AliasedNegatedMatcher.new(match(*args), ->{})
    end

    matcher :with_param do |param, value|
      match do |url|
        if value.is_a?(Array)
          return false unless url =~ %r{[?&]#{param}=(\d+(%2C\d+)*)(?:&|$)}
          actual = $1.split('%2C').map(&:to_i)
          return actual.sort == value.sort
        else
          url =~ %r{[?&]#{param}=#{value}(?:&|$)}
        end
      end
    end

    matcher :with_param_present do |param|
      match do |url|
        url =~ %r{[?&]#{param}=}
      end
    end

    describe "jwt" do
      it "signs with the base64 decoded secret from the configuration" do
        jwt = Services::AddressBook.jwt
        expect(lambda{ Canvas::Security.decode_jwt(jwt, [@secret]) }).not_to raise_exception
      end

      it "includes current time as ait claim" do
        Timecop.freeze do
          jwt = Services::AddressBook.jwt
          claims = Canvas::Security.decode_jwt(jwt, [@secret])
          expect(Time.at(claims[:iat])).to be_within(1).of(Time.now)
        end
      end
    end

    describe "recipients" do
      it "includes an Authorization header with JWT in request" do
        Timecop.freeze do
          jwt = Services::AddressBook.jwt
          expect_request(anything, headers: hash_including('Authorization' => %r{Bearer #{jwt}}))
          Services::AddressBook.recipients(sender: @sender)
        end
      end

      it "makes request from /recipients in service" do
        expect_request(%r{^#{@app_host}/recipients\?})
        Services::AddressBook.recipients(sender: @sender)
      end

      it "normalizes sender from a User to its global ID as for_sender param" do
        expect_request(with_param(:for_sender, @sender.global_id))
        Services::AddressBook.recipients(sender: @sender)
      end

      it "normalizes sender from an ID to a global ID as for_sender param" do
        expect_request(with_param(:for_sender, @sender.global_id))
        Services::AddressBook.recipients(sender: @sender.id)
      end

      it "includes the sender's visible accounts" do
        account1 = account_model
        account2 = account_model
        account_admin_user(user: @sender, account: account1)
        account_admin_user(user: @sender, account: account2)
        expect_request(with_param(:visible_account_ids, [account1.global_id, account2.global_id]))
        Services::AddressBook.recipients(sender: @sender)
      end

      it "includes the sender's restricted courses" do
        course1 = course_with_observer(user: @sender, active_all: true).course
        course2 = course_with_observer(user: @sender, active_all: true).course
        expect_request(with_param(:restricted_course_ids, [course1.global_id, course2.global_id]))
        Services::AddressBook.recipients(sender: @sender)
      end

      it "normalizes context from e.g. a Course to its global asset string as in_context param" do
        expect_request(with_param(:in_context, @course.global_asset_string))
        Services::AddressBook.recipients(context: @course)
      end

      it "normalizes context from an asset string to a global asset string as in_context param" do
        expect_request(with_param(:in_context, @course.global_asset_string))
        Services::AddressBook.recipients(context: @course.asset_string)
      end

      it "normalizes context from a scoped asset string to a scoped global asset string as in_context param" do
        expect_request(with_param(:in_context, "#{@course.global_asset_string}_students"))
        Services::AddressBook.recipients(context: "#{@course.asset_string}_students")
      end

      it "normalizes user_ids from Users to a comma-separated list of their global IDs as user_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(with_param(:user_ids, [recipient1.global_id, recipient2.global_id]))
        Services::AddressBook.recipients(user_ids: [recipient1, recipient2])
      end

      it "normalizes user_ids from IDs to a comma-separated list of global IDs as user_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(with_param(:user_ids, [recipient1.global_id, recipient2.global_id]))
        Services::AddressBook.recipients(user_ids: [recipient1.id, recipient2.id])
      end

      it "normalizes exclude_ids from Users to a comma-separated list of their global IDs as exclude_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(with_param(:exclude_ids, [recipient1.global_id, recipient2.global_id]))
        Services::AddressBook.recipients(exclude_ids: [recipient1, recipient2])
      end

      it "normalizes exclude_ids from IDs to a comma-separated list of global IDs as exclude_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(with_param(:exclude_ids, [recipient1.global_id, recipient2.global_id]))
        Services::AddressBook.recipients(exclude_ids: [recipient1.id, recipient2.id])
      end

      it "normalizes weak_checks to 1 if truthy" do
        expect_request(with_param(:weak_checks, 1))
        Services::AddressBook.recipients(weak_checks: true)
      end

      it "omits weak_checks if falsey" do
        expect_request(not_match(with_param_present(:weak_checks)))
        Services::AddressBook.recipients(weak_checks: false)
      end

      it "normalizes ignore_result to 1 if truthy" do
        expect_request(with_param(:ignore_result, 1))
        Services::AddressBook.recipients(ignore_result: true)
      end

      it "reshapes results returned from service endpoint" do
        stub_response(anything, example_response)
        result = Services::AddressBook.recipients(@sender)
        expect(result.user_ids).to eql([ 10000000000002, 10000000000005 ])
        expect(result.common_contexts).to eql({
          10000000000002 => {
            courses: { 10000000000001 => ['TeacherEnrollment'] },
            groups: {}
          },
          10000000000005 => {
            courses: { 10000000000002 => ['StudentEnrollment'] },
            groups: { 10000000000001 => ['Member'] }
          }
        })
        expect(result.cursors).to eql([ 8, 12 ])
      end

      it "uses timeout protection and returns sane value on timeout" do
        allow(Canvas).to receive(:redis_enabled?).and_return(true)
        allow(Canvas).to receive(:redis).and_return(double)
        allow(Canvas.redis).to receive(:get).with("service:timeouts:address_book:error_count").and_return(4)
        expect(Rails.logger).to receive(:error).with("Skipping service call due to error count: address_book 4")
        result = nil
        expect { result = Services::AddressBook.recipients(@sender) }.not_to raise_error
        expect(result.user_ids).to eq([])
        expect(result.common_contexts).to eq({})
        expect(result.cursors).to eq([])
      end

      it "reads separate timeout setting when ignoring result (for performance tapping)" do
        allow(Canvas).to receive(:redis_enabled?).and_return(true)
        allow(Canvas).to receive(:redis).and_return(double)
        allow(Canvas.redis).to receive(:get).with("service:timeouts:address_book_performance_tap:error_count").and_return(4)
        expect(Rails.logger).to receive(:error).with("Skipping service call due to error count: address_book_performance_tap 4")
        result = nil
        expect { result = Services::AddressBook.recipients(sender: @sender, ignore_result: true) }.not_to raise_error
        expect(result.user_ids).to eq([])
        expect(result.common_contexts).to eq({})
        expect(result.cursors).to eq([])
      end

      it "returns empty response when ignoring result, regardless of what service returns" do
        stub_response(anything, example_response)
        result = Services::AddressBook.recipients(sender: @sender, ignore_result: true)
        expect(result.user_ids).to eql([])
        expect(result.common_contexts).to eql({})
        expect(result.cursors).to eql([])
      end

      it "reports errors in service request but then returns sane value" do
        stub_response(anything, { 'errors' => { 'something' => 'went wrong' } }, status: 400)
        expect(Canvas::Errors).to receive(:capture)
        result = nil
        expect { result = Services::AddressBook.recipients(@sender) }.not_to raise_error
        expect(result.user_ids).to eq([])
        expect(result.common_contexts).to eq({})
        expect(result.cursors).to eq([])
      end
    end

    describe "count_recipients" do
      before do
        @count = 5
        @response = { 'count' => @count }
      end

      it "makes request from /recipients/count in service" do
        expect_request(%r{^#{@app_host}/recipients/count\?}, body: @response)
        Services::AddressBook.count_recipients(sender: @sender)
      end

      it "normalizes sender same as recipients" do
        expect_request(with_param(:for_sender, @sender.global_id), body: @response)
        Services::AddressBook.count_recipients(sender: @sender)
      end

      it "normalizes context same as recipients" do
        expect_request(with_param(:in_context, @course.global_asset_string), body: @response)
        Services::AddressBook.count_recipients(context: @course)
      end

      it "extracts count from response from service endpoint" do
        stub_response(anything, @response)
        count = Services::AddressBook.count_recipients(sender: @sender, context: @course)
        expect(count).to eql(@count)
      end
    end

    describe "common_contexts" do
      it "makes a recipient request" do
        expect_request(%r{/recipients\?})
        Services::AddressBook.common_contexts(@sender, [1, 2, 3])
      end

      it "passes the sender to the recipients call" do
        expect_request(with_param_present(:for_sender))
        Services::AddressBook.common_contexts(@sender, [1, 2, 3])
      end

      it "passes the user_ids to the recipients call" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(with_param(:user_ids, [recipient1.global_id, recipient2.global_id]))
        Services::AddressBook.common_contexts(@sender, [recipient1.id, recipient2.id])
      end
    end

    describe "roles_in_context" do
      it "makes a recipient request with no sender" do
        expect_request(%r{/recipients\?})
        expect_request(with_param_present(:for_sender)).never
        Services::AddressBook.roles_in_context(@course, [1, 2, 3])
      end

      it "passes the user_ids to the recipients call" do
        recipient1 = user_model
        recipient2 = user_model
        expect(recipient1.global_id).to eql(Shard.global_id_for(recipient1.id))
        expect_request(with_param(:user_ids, [recipient1.global_id, recipient2.global_id]))
        Services::AddressBook.roles_in_context(@course, [recipient1.id, recipient2.id])
      end

      it "passes the context to the recipients call" do
        expect_request(with_param(:in_context, @course.global_asset_string))
        Services::AddressBook.roles_in_context(@course, [1, 2, 3])
      end

      it "uses the course as the context for a course section" do
        expect_request(with_param(:in_context, @course.global_asset_string))
        Services::AddressBook.roles_in_context(@course.default_section, [1, 2, 3])
      end
    end

    describe "known_in_context" do
      it "makes a recipient request" do
        expect_request(%r{/recipients\?})
        Services::AddressBook.known_in_context(@sender, @course.asset_string)
      end

      it "passes the sender to the recipients call if not is_admin" do
        expect_request(with_param(:for_sender, @sender.global_id))
        Services::AddressBook.known_in_context(@sender, @course.asset_string)
      end

      it "omits the sender form the recipients call if is_admin" do
        expect_request(not_match(with_param_present(:for_sender)))
        Services::AddressBook.known_in_context(@sender, @course.asset_string, true)
      end

      it "passes the context to the recipients call" do
        expect_request(with_param(:in_context, @course.global_asset_string))
        Services::AddressBook.known_in_context(@sender, @course.asset_string)
      end

      it "returns an ordered list of ids and a hash of contexts per id" do
        stub_response(anything, example_response)
        user_ids, common_contexts = Services::AddressBook.known_in_context(@sender, @course.asset_string)
        expect(user_ids).to eql([ 10000000000002, 10000000000005 ])
        expect(common_contexts).to eql({
          10000000000002 => {
            courses: { 10000000000001 => ['TeacherEnrollment'] },
            groups: {}
          },
          10000000000005 => {
            courses: { 10000000000002 => ['StudentEnrollment'] },
            groups: { 10000000000001 => ['Member'] }
          }
        })
      end
    end

    describe "count_in_context" do
      before do
        @count = 5
        @response = { 'count' => @count }
      end

      it "makes a recipient/count request" do
        expect_request(%r{/recipients/count\?})
        Services::AddressBook.count_in_context(@sender, @course.asset_string)
      end

      it "passes the sender to the count_recipients call" do
        expect_request(with_param(:for_sender, @sender.global_id))
        Services::AddressBook.count_in_context(@sender, @course.asset_string)
      end

      it "passes the context to the count_recipients call" do
        expect_request(with_param(:in_context, @course.global_asset_string))
        Services::AddressBook.count_in_context(@sender, @course.asset_string)
      end

      it "returns the count from count_recipients call" do
        expect_request(anything, body: @response)
        count = Services::AddressBook.count_in_context(@sender, 'course_1')
        expect(count).to eql(@count)
      end
    end

    describe "search_users" do
      it "makes a recipient request" do
        expect_request(%r{/recipients\?})
        Services::AddressBook.search_users(@sender, {search: 'bob'}, {})
      end

      it "only has search parameter by default" do
        expect_request(with_param(:search, 'bob'))
        expect_request(with_param_present(:in_context)).never
        expect_request(with_param_present(:exclude_ids)).never
        expect_request(with_param_present(:weak_checks)).never
        Services::AddressBook.search_users(@sender, {search: 'bob'}, {})
      end

      it "passes context to recipients call" do
        expect_request(with_param_present(:in_context))
        Services::AddressBook.search_users(@sender, {search: 'bob', context: @course}, {})
      end

      it "includes sender if is_admin but no context given" do
        expect_request(with_param_present(:for_sender))
        Services::AddressBook.search_users(@sender, {search: 'bob', is_admin: true}, {})
      end

      it "omits sender if is_admin specified with context" do
        expect_request(not_match(with_param_present(:sender)))
        Services::AddressBook.search_users(@sender, {search: 'bob', context: @course, is_admin: true}, {})
      end

      it "passes exclude_ids to recipients call" do
        expect_request(with_param_present(:exclude_ids))
        Services::AddressBook.search_users(@sender, {search: 'bob', exclude_ids: [1, 2, 3]}, {})
      end

      it "passes weak_checks flag along to recipients" do
        expect_request(with_param_present(:weak_checks))
        Services::AddressBook.search_users(@sender, {search: 'bob', weak_checks: true}, {})
      end

      it "returns ids, contexts, and cursors" do
        stub_response(anything, example_response)
        user_ids, common_contexts, cursors = Services::AddressBook.search_users(@sender, {search: 'bob'}, {})
        expect(user_ids).to eql([ 10000000000002, 10000000000005 ])
        expect(common_contexts).to eql({
          10000000000002 => {
            courses: { 10000000000001 => ['TeacherEnrollment'] },
            groups: {}
          },
          10000000000005 => {
            courses: { 10000000000002 => ['StudentEnrollment'] },
            groups: { 10000000000001 => ['Member'] }
          }
        })
        expect(cursors).to eql([ 8, 12 ])
      end

      it "passes cursor parameter to the service" do
        expect_request(with_param(:cursor, 12))
        Services::AddressBook.search_users(@sender, {search: 'bob'}, {cursor: 12})
      end

      it "passes per_page parameter to the service" do
        expect_request(with_param(:per_page, 20))
        Services::AddressBook.search_users(@sender, {search: 'bob'}, {per_page: 20})
      end
    end
  end
end
