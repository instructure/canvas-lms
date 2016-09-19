require_relative "../../spec_helper"

module Services
  describe AddressBook do
    before do
      @app_host = "address-book"
      Canvas::DynamicSettings.stubs(:find).
        with("address-book").
        returns({ "app-host" => @app_host })
      @sender = user_model
      @course = course_model
    end

    def expect_request(url, body={})
      CanvasHttp.expects(:get).with(url).returns(stub(body: body.to_json, code: 200))
    end

    def stub_response(url, body, code=200)
      CanvasHttp.stubs(:get).with(url).returns(stub(body: body.to_json, code: code))
    end

    describe "recipients" do
      it "makes request from /recipients in service" do
        expect_request(regexp_matches(%r{^#{@app_host}/recipients\?}))
        Services::AddressBook.recipients(sender: @sender)
      end

      it "normalizes sender from a User to its global ID as for_sender param" do
        expect_request(regexp_matches(%r{for_sender=#{@sender.global_id}}))
        Services::AddressBook.recipients(sender: @sender)
      end

      it "normalizes sender from an ID to a global ID as for_sender param" do
        expect_request(regexp_matches(%r{for_sender=#{@sender.global_id}}))
        Services::AddressBook.recipients(sender: @sender.id)
      end

      it "normalizes context from e.g. a Course to its global asset string as in_context param" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}))
        Services::AddressBook.recipients(context: @course)
      end

      it "normalizes context from an asset string to a global asset string as in_context param" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}))
        Services::AddressBook.recipients(context: @course.asset_string)
      end

      it "normalizes context from a scoped asset string to a scoped global asset string as in_context param" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}_students}))
        Services::AddressBook.recipients(context: "#{@course.asset_string}_students")
      end

      it "normalizes user_ids from Users to a comma-separated list of their global IDs as user_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(regexp_matches(%r{user_ids=#{recipient1.global_id}%2C#{recipient2.global_id}}))
        Services::AddressBook.recipients(user_ids: [recipient1, recipient2])
      end

      it "normalizes user_ids from IDs to a comma-separated list of global IDs as user_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(regexp_matches(%r{user_ids=#{recipient1.global_id}%2C#{recipient2.global_id}}))
        Services::AddressBook.recipients(user_ids: [recipient1.id, recipient2.id])
      end

      it "normalizes exclude_ids from Users to a comma-separated list of their global IDs as exclude_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(regexp_matches(%r{exclude_ids=#{recipient1.global_id}%2C#{recipient2.global_id}}))
        Services::AddressBook.recipients(exclude_ids: [recipient1, recipient2])
      end

      it "normalizes exclude_ids from IDs to a comma-separated list of global IDs as exclude_ids param" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(regexp_matches(%r{exclude_ids=#{recipient1.global_id}%2C#{recipient2.global_id}}))
        Services::AddressBook.recipients(exclude_ids: [recipient1.id, recipient2.id])
      end

      it "normalizes weak_checks to 1 if truthy" do
        expect_request(regexp_matches(%r{weak_checks=1}))
        Services::AddressBook.recipients(weak_checks: true)
      end

      it "omits weak_checks if falsey" do
        expect_request(Not(regexp_matches(%r{weak_checks=})))
        Services::AddressBook.recipients(weak_checks: false)
      end

      it "reshapes results returned from service endpoint" do
        stub_response(anything, {
          '10000000000002' => [
            { 'context_type' => 'course', 'context_id' => '10000000000001', 'roles' => ['TeacherEnrollment'] }
          ],
          '10000000000005' => [
            { 'context_type' => 'course', 'context_id' => '10000000000002', 'roles' => ['StudentEnrollment'] },
            { 'context_type' => 'group', 'context_id' => '10000000000001', 'roles' => ['Member'] }
          ]
        })
        result = Services::AddressBook.recipients(@sender)
        expect(result).to eql({
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

      it "uses timeout protection and returns sane value on timeout" do
        Canvas.stubs(:redis_enabled?).returns(true)
        Canvas.stubs(:redis).returns(stub())
        Canvas.redis.stubs(:get).with("service:timeouts:address_book").returns(4)
        Rails.logger.expects(:error).with("Skipping service call due to error count: address_book 4")
        result = nil
        expect { result = Services::AddressBook.recipients(@sender) }.not_to raise_error
        expect(result).to eq({})
      end

      it "reports errors in service request but then returns sane value" do
        stub_response(anything, { 'errors' => { 'something' => 'went wrong' } }, 400)
        Canvas::Errors.expects(:capture)
        result = nil
        expect { result = Services::AddressBook.recipients(@sender) }.not_to raise_error
        expect(result).to eql({})
      end
    end

    describe "count_recipients" do
      before :each do
        @count = 5
        @response = { 'count' => @count }
      end

      it "makes request from /recipients/count in service" do
        expect_request(regexp_matches(%r{^#{@app_host}/recipients/count\?}), @response)
        Services::AddressBook.count_recipients(sender: @sender)
      end

      it "normalizes sender same as recipients" do
        expect_request(regexp_matches(%r{for_sender=#{@sender.global_id}}), @response)
        Services::AddressBook.count_recipients(sender: @sender)
      end

      it "normalizes context same as recipients" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}), @response)
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
        expect_request(regexp_matches(%r{/recipients\?}))
        Services::AddressBook.common_contexts(@sender, [1, 2, 3])
      end

      it "passes the sender to the recipients call" do
        expect_request(regexp_matches(%r{sender=}))
        Services::AddressBook.common_contexts(@sender, [1, 2, 3])
      end

      it "passes the user_ids to the recipients call" do
        recipient1 = user_model
        recipient2 = user_model
        expect_request(regexp_matches(%r{user_ids=#{recipient1.global_id}%2C#{recipient2.global_id}}))
        Services::AddressBook.common_contexts(@sender, [recipient1.id, recipient2.id])
      end
    end

    describe "roles_in_context" do
      it "makes a recipient request with no sender" do
        expect_request(regexp_matches(%r{/recipients\?}))
        expect_request(regexp_matches(%r{sender=})).never
        Services::AddressBook.roles_in_context(@course, [1, 2, 3])
      end

      it "passes the user_ids to the recipients call" do
        recipient1 = user_model
        recipient2 = user_model
        expect(recipient1.global_id).to eql(Shard.global_id_for(recipient1.id))
        expect_request(regexp_matches(%r{user_ids=#{recipient1.global_id}%2C#{recipient2.global_id}}))
        Services::AddressBook.roles_in_context(@course, [recipient1.id, recipient2.id])
      end

      it "passes the context to the recipients call" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}))
        Services::AddressBook.roles_in_context(@course, [1, 2, 3])
      end

      it "uses the course as the context for a course section" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}))
        Services::AddressBook.roles_in_context(@course.default_section, [1, 2, 3])
      end
    end

    describe "known_in_context" do
      it "makes a recipient request" do
        expect_request(regexp_matches(%r{/recipients\?}))
        Services::AddressBook.known_in_context(@sender, @course.asset_string)
      end

      it "passes the sender to the recipients call if not is_admin" do
        expect_request(regexp_matches(%r{sender=#{@sender.global_id}}))
        Services::AddressBook.known_in_context(@sender, @course.asset_string)
      end

      it "omits the sender form the recipients call if is_admin" do
        expect_request(Not(regexp_matches(%r{sender=})))
        Services::AddressBook.known_in_context(@sender, @course.asset_string, true)
      end

      it "passes the context to the recipients call" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}))
        Services::AddressBook.known_in_context(@sender, @course.asset_string)
      end
    end

    describe "count_in_context" do
      before :each do
        @count = 5
        @response = { 'count' => @count }
      end

      it "makes a recipient/count request" do
        expect_request(regexp_matches(%r{/recipients/count\?}))
        Services::AddressBook.count_in_context(@sender, @course.asset_string)
      end

      it "passes the sender to the count_recipients call" do
        expect_request(regexp_matches(%r{sender=#{@sender.global_id}}))
        Services::AddressBook.count_in_context(@sender, @course.asset_string)
      end

      it "passes the context to the count_recipients call" do
        expect_request(regexp_matches(%r{in_context=#{@course.global_asset_string}}))
        Services::AddressBook.count_in_context(@sender, @course.asset_string)
      end

      it "returns the count from count_recipients call" do
        expect_request(anything, @response)
        count = Services::AddressBook.count_in_context(@sender, 'course_1')
        expect(count).to eql(@count)
      end
    end

    describe "search_users" do
      it "makes a recipient request" do
        expect_request(regexp_matches(%r{/recipients\?}))
        Services::AddressBook.search_users(@sender, search: 'bob')
      end

      it "only has search parameter by default" do
        expect_request(regexp_matches(%r{search=bob}))
        expect_request(regexp_matches(%r{in_context=})).never
        expect_request(regexp_matches(%r{exclude_ids=})).never
        expect_request(regexp_matches(%r{weak_checks=})).never
        Services::AddressBook.search_users(@sender, search: 'bob')
      end

      it "passes context to recipients call" do
        expect_request(regexp_matches(%r{in_context=}))
        Services::AddressBook.search_users(@sender, search: 'bob', context: @course)
      end

      it "includes sender if is_admin but no context given" do
        expect_request(regexp_matches(%r{sender=}))
        Services::AddressBook.search_users(@sender, search: 'bob', is_admin: true)
      end

      it "omits sender if is_admin specified with context" do
        expect_request(Not(regexp_matches(%r{sender=})))
        Services::AddressBook.search_users(@sender, search: 'bob', context: @course, is_admin: true)
      end

      it "passes exclude_ids to recipients call" do
        expect_request(regexp_matches(%r{exclude_ids=}))
        Services::AddressBook.search_users(@sender, search: 'bob', exclude_ids: [1, 2, 3])
      end

      it "passes weak_checks flag along to recipients" do
        expect_request(regexp_matches(%r{weak_checks=}))
        Services::AddressBook.search_users(@sender, search: 'bob', weak_checks: true)
      end

      it "returns both result and finished flag" do
        stub_response(anything, {
          '10000000000002' => [
            { 'context_type' => 'course', 'context_id' => '10000000000001', 'roles' => ['TeacherEnrollment'] }
          ],
          '10000000000005' => [
            { 'context_type' => 'course', 'context_id' => '10000000000002', 'roles' => ['StudentEnrollment'] },
            { 'context_type' => 'group', 'context_id' => '10000000000001', 'roles' => ['Member'] }
          ]
        })
        result, finished = Services::AddressBook.search_users(@sender, search: 'bob')
        expect(result).to eql({
          10000000000002 => {
            courses: { 10000000000001 => ['TeacherEnrollment'] },
            groups: {}
          },
          10000000000005 => {
            courses: { 10000000000002 => ['StudentEnrollment'] },
            groups: { 10000000000001 => ['Member'] }
          }
        })
        expect(finished).to be_truthy
      end

      # [CNVS-31303] TODO
      it "passes pagination parameters to the service"
      it "returns not finished if the service response indicates another page"
    end
  end
end
