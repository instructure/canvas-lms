# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

describe Canvas::CacheRegister do
  before do
    skip("require redis") unless Canvas.redis_enabled?
    allow(Canvas::CacheRegister).to receive(:enabled?).and_return(true)
  end

  def set_revert!
    allow(Canvas::CacheRegister).to receive(:enabled?).and_return(false)
  end

  before :once do
    @user = User.create!
  end

  let(:time1) { 1.minute.from_now }
  let(:time2) { 2.minutes.from_now }

  def to_stamp(time)
    time.to_fs(User.cache_timestamp_format)
  end

  context "reading" do
    it "automatically sets the key to the current time if it doesn't exist" do
      Timecop.freeze(time1) do
        @key = @user.cache_key(:enrollments)
        expect(@key).to include(to_stamp(time1))
      end

      Timecop.freeze(time2) do
        expect(@user.cache_key(:enrollments)).to eq @key # stays the same
      end
    end

    it "uses updated_at if reverted" do
      set_revert!
      Timecop.freeze(time1) do
        key = @user.cache_key(:enrollments)
        expect(key).to_not include(to_stamp(time1))
        expect(key).to include(to_stamp(@user.updated_at))
      end
    end

    it "separates keys by type" do
      Timecop.freeze(time1) { @user.cache_key(:enrollments) }
      Timecop.freeze(time2) { expect(@user.cache_key(:account_users)).to include(to_stamp(time2)) }
    end

    it "separates keys by user" do
      user2 = User.create!
      Timecop.freeze(time1) { @user.cache_key(:enrollments) }
      Timecop.freeze(time2) { expect(user2.cache_key(:enrollments)).to include(to_stamp(time2)) }
    end

    it "checks the types in dev/test" do
      expect { @user.cache_key(:blah) }.to raise_error("invalid cache_key type 'blah' for User")
    end

    it "uses the same redis node for each object" do
      real_redis = Canvas.redis # may not actually be distributed so we'll make do
      fake_redis = double
      allow(Canvas).to receive(:redis).and_return(fake_redis)
      base_key = User.base_cache_register_key_for(@user.id)
      # should call node_for with the same base key each time
      expect(fake_redis).to receive(:node_for).with(base_key).and_return(real_redis).exactly(2).times
      @user.cache_key(:enrollments)
      @user.cache_key(:groups)
    end
  end

  context "invalidation" do
    context "for a single record" do
      it "updates specified cache types" do
        Timecop.freeze(time1) do
          %i[enrollments account_users groups].each do |k|
            @user.cache_key(k)
          end
        end

        @user.clear_cache_key(:enrollments, :account_users) # delete keys from redis

        Timecop.freeze(time2) do
          expect(@user.cache_key(:enrollments)).to include(to_stamp(time2))
          expect(@user.cache_key(:account_users)).to include(to_stamp(time2))

          expect(@user.cache_key(:groups)).to include(to_stamp(time1)) # left this one alone
        end
      end

      it "checks the types in dev/test" do
        expect { @user.clear_cache_key(:blah) }.to raise_error("invalid cache_key type 'blah' for User")
      end

      it "does not do anything if reverted" do
        set_revert!
        expect(Canvas::CacheRegister).not_to receive(:redis)
        @user.clear_cache_key(:enrollments)
      end

      it "uses the same redis node for each object" do
        real_redis = Canvas.redis # may not actually be distributed so we'll make do
        fake_redis = double
        allow(Canvas).to receive(:redis).and_return(fake_redis)
        base_key = User.base_cache_register_key_for(@user.id)
        # should call node_for with the same base key each time
        expect(fake_redis).to receive(:node_for).with(base_key).and_return(real_redis).once
        @user.clear_cache_key(:enrollments, :groups)
      end
    end

    context "multiple users" do
      it "works with an array of users" do
        users = (0..2).map { User.create! }
        Timecop.freeze(time1) do
          users.each do |u|
            u.cache_key(:enrollments)
            u.cache_key(:groups)
          end
        end

        User.clear_cache_keys(users, :enrollments)

        Timecop.freeze(time2) do
          users.each do |u|
            expect(u.cache_key(:enrollments)).to include(to_stamp(time2))
            expect(u.cache_key(:groups)).to include(to_stamp(time1)) # unchanged
          end
        end
      end

      it "works with a relation" do
        course_with_teacher(active_all: true)
        Timecop.freeze(time1) do
          @teacher.cache_key(:enrollments)
        end

        @course.teachers.clear_cache_keys(:enrollments)

        Timecop.freeze(time2) do
          expect(@teacher.cache_key(:enrollments)).to include(to_stamp(time2))
        end
      end

      it "is able to touch the users as well (unless skipped)" do
        users = (0..2).map { User.create! }
        Timecop.freeze(time1) do
          users.each { |u| u.cache_key(:enrollments) }
        end

        Timecop.freeze(time2) do
          User.touch_and_clear_cache_keys(users.map(&:id), :enrollments)
          users.each do |u|
            expect(u.cache_key(:enrollments)).to include(to_stamp(time2))
            expect(u.reload.updated_at.to_i).to eq time2.to_i
          end
        end

        time3 = 3.minutes.from_now
        expect(User).to receive(:skip_touch_for_type?).with(:enrollments).and_return(true)

        Timecop.freeze(time3) do
          User.touch_and_clear_cache_keys(users.map(&:id), :enrollments)
          users.each do |u|
            expect(u.cache_key(:enrollments)).to include(to_stamp(time3))
            expect(u.reload.updated_at.to_i).to eq time2.to_i # don't touch
          end
        end
      end

      context "with sharding" do
        specs_require_sharding

        before do
          @users = []
          @users << User.create!
          @shard1.activate { @users << User.create! }
          Timecop.freeze(time1) do
            @users.each do |u|
              u.cache_key(:enrollments)
              u.cache_key(:groups)
            end
          end
        end

        it "reading should be shard-independent" do
          @shard2.activate do
            @users.each do |u|
              expect(u.cache_key(:enrollments)).to include(to_stamp(time1))
            end
          end
        end

        it "works with a multi-shard array" do
          User.clear_cache_keys(@users, :enrollments)
          Timecop.freeze(time2) do
            @users.each do |u|
              expect(u.cache_key(:enrollments)).to include(to_stamp(time2))
              expect(u.cache_key(:groups)).to include(to_stamp(time1)) # unchanged
            end
          end
        end

        it "fails trying to clear things that aren't resolvable by to a global id" do
          weird_hash = { what: @users.first }
          expect do
            User.clear_cache_keys(weird_hash, :enrollments)
          end.to raise_error("invalid argument for cache clearing #{weird_hash.to_a.first}")
        end

        it "works with a multi-shard relation" do
          User.where(id: @users.map(&:global_id)).clear_cache_keys(:enrollments)
          Timecop.freeze(time2) do
            @users.each do |u|
              expect(u.cache_key(:enrollments)).to include(to_stamp(time2))
              expect(u.cache_key(:groups)).to include(to_stamp(time1)) # unchanged
            end
          end
        end

        it "doesn't raise when passed a new record" do
          expect do
            User.clear_cache_keys(User.new, :enrollments)
          end.not_to raise_error
        end
      end
    end
  end

  context "batch fetch" do
    specs_require_cache(:redis_cache_store)

    def check_cache
      some_key = "some_base_key/withstuff"
      some_value = "some value"
      some_other_value = "some other value"

      Timecop.freeze(time1) do
        res1 = Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups]) do
          some_value
        end
        expect(res1).to eq some_value
      end

      Timecop.freeze(time2) do
        expect(@user.cache_key(:enrollments)).to include(to_stamp(time1)) # sets the key like usual

        res2 = Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups]) do
          some_other_value
        end
        expect(res2).to eq some_value # stays the same

        @user.clear_cache_key(:groups) # invalidate one component
        res3 = Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups]) do
          some_other_value
        end
        expect(res3).to eq some_other_value
      end
    end

    it "is able to do a fetch using new cache keys in a single call" do
      expect(Rails.cache).to receive(:fetch_with_cache_register).at_least(:once).and_call_original
      check_cache
    end

    it "regenerates when fetch_with_cache_register can't generate a key" do
      expect(Canvas::CacheRegister.lua).to receive(:run).with(:get_with_batched_keys, anything, anything, anything).and_raise(Redis::ConnectionError.new)
      expect(Rails.cache.redis).not_to receive(:set)

      expect(Rails.cache.fetch_with_batched_keys("some_base_key/withstuff", batch_object: @user, batched_keys: [:enrollments, :groups]) { "some value" }).to eq "some value"
    end

    it "still works with expiration" do
      some_key = "some_base_key/withstuff"
      some_value = "some value"
      some_other_value = "some other value"

      Timecop.freeze(time1) do
        Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups], expires_in: 5.minutes) do
          some_value
        end
      end
      Timecop.freeze(time2) do
        res2 = Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups], expires_in: 5.minutes) do
          some_other_value
        end
        expect(res2).to eq some_value # not expired yet
      end
      Timecop.freeze(10.minutes.from_now) do
        res3 = Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups], expires_in: 5.minutes) do
          some_other_value
        end
        expect(res3).to eq some_other_value
      end
    end

    it "is separate by user" do
      some_key = "some_base_key/withstuff"
      some_value = "some value"
      some_other_value = "some other value"
      user2 = User.create!

      Timecop.freeze(time1) do
        Rails.cache.fetch_with_batched_keys(some_key, batch_object: @user, batched_keys: [:enrollments, :groups]) do
          some_value
        end
        res2 = Rails.cache.fetch_with_batched_keys(some_key, batch_object: user2, batched_keys: [:enrollments, :groups]) do
          some_other_value
        end
        expect(res2).to eq some_other_value
      end
    end

    it "falls back to a regular fetch (appending the keys) if not using a redis cache store" do
      enable_cache(:memory_store) do
        expect(Rails.cache).not_to receive(:fetch_with_cache_register)
        check_cache
      end
    end

    it "does not cache on a new record" do
      expect(Canvas::CacheRegister).not_to receive(:redis)
      res1 = Rails.cache.fetch_with_batched_keys("blah", batch_object: User.new, batched_keys: [:enrollments]) { 1 }
      expect(res1).to eq 1
    end

    it "checks the key types" do
      expect do
        Rails.cache.fetch_with_batched_keys("k", batch_object: @user, batched_keys: :blah) { "v" }
      end.to raise_error("invalid cache_key type 'blah' for User")
    end
  end

  context "without an object" do
    it "tries to find the cache key by the id alone" do
      @user2 = User.create!
      Timecop.freeze(time1) do
        @user.cache_key(:enrollments)
      end

      Timecop.freeze(time2) do
        expect(User.cache_key_for_id(@user.id, :enrollments)).to include(to_stamp(time1))
        expect(User.cache_key_for_id(@user2.id, :enrollments)).to include(to_stamp(time2))
      end
    end

    it "returns a key for 'now' if cache register is disabled" do
      set_revert!
      Timecop.freeze(time1) do
        @user.cache_key(:enrollments)
      end
      Timecop.freeze(time2) do
        expect(User.cache_key_for_id(@user.id, :enrollments)).to include(to_stamp(time2))
      end
    end

    it "checks the types in dev/test" do
      expect { User.cache_key_for_id(@user.id, :blah) }.to raise_error("invalid cache_key type 'blah' for User")
    end
  end

  context "redis node lookup and sharding" do
    specs_require_sharding
    specs_require_cache(:redis_cache_store)

    before do
      @user = @shard1.activate { User.create! }
      @base_key = User.base_cache_register_key_for(@user)
    end

    def expect_redis_call
      expect(Canvas::CacheRegister).to receive(:redis).with(@base_key, @user.shard).and_call_original
    end

    it "passes the object's shard when looking up node for cache_key" do
      expect(Canvas::CacheRegister).to receive(:redis).with(@base_key, @user.shard, prefer_multi_cache: false).and_call_original
      @user.cache_key(:enrollments)
    end

    it "passes the object's shard when looking up node for clear_cache_keys" do
      expect_redis_call
      User.clear_cache_keys([@user.id], :enrollments)
    end

    it "passes the object's shard when looking up node for fetch_with_batched_keys" do
      expect_redis_call
      Rails.cache.fetch_with_batched_keys("somekey", batch_object: @user, batched_keys: [:enrollments]) do
        "something"
      end
    end
  end

  context "multi-cache preference" do
    it "retrieves multi-cache redis when preferred" do
      allow(Canvas::CacheRegister).to receive(:can_use_multi_cache_redis?).and_return(true)
      mock_redis = double
      cache = double(redis: mock_redis)
      allow(MultiCache).to receive(:cache).and_return(cache)
      expect(Canvas::CacheRegister.redis("key", Shard.default, prefer_multi_cache: true)).to eq mock_redis
    end

    it "prefers multi-cache when retreiving a configured key" do
      base_key = Account.base_cache_register_key_for(Account.default)
      expect(Canvas::CacheRegister).to receive(:redis).with(base_key, Shard.default, prefer_multi_cache: true).and_call_original
      Account.default.cache_key(:feature_flags)
    end

    it "uses multi-cache delete when clearing a configured key" do
      key = "{#{Account.base_cache_register_key_for(Account.default)}}/feature_flags"
      allow(Canvas::CacheRegister).to receive(:can_use_multi_cache_redis?).and_return(true)
      expect(Canvas::CacheRegister).to_not receive(:redis)
      expect(MultiCache).to receive(:delete).with(key, { unprefixed_key: true })
      Account.default.clear_cache_key(:feature_flags)
    end
  end
end
