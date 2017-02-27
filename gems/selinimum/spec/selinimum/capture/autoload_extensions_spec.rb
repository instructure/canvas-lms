require "selinimum/capture/autoload_extensions"
require "active_support/core_ext/string/inflections"

describe Selinimum::Capture::AutoloadExtensions do
  subject { described_class }

  def cache_constants(constant = "SelinimumFoo")
    subject.cache_constants(constant.underscore + ".rb", [constant]) { yield }
  end

  describe ".cache_constants" do
    context "without a corresponding cached autoload" do
      it "populates the cache with defined constants" do
        cache_constants { SelinimumFoo = Class.new }
        cached_autoload = subject.cached_autoloads["selinimum_foo.rb"]
        expect(cached_autoload).not_to be_nil
      end

      it "doesn't cache if no constants are defined" do
        cache_constants { }
        cached_autoload = subject.cached_autoloads["selinimum_foo.rb"]
        expect(cached_autoload).to be_nil
      end

      it "returns the block's expression" do
        expect(cache_constants { "lol" }).to eql("lol")
      end

      context "dependency tracking" do
        it "temporarily resets top-level sibling autoloads" do
          cache_constants("SelinimumFoo") do
            SelinimumFoo = Class.new
          end

          cache_constants("SelinimumBar") do
            expect(Object.const_defined?("SelinimumFoo")).to be false
            SelinimumBar = Class.new
          end

          expect(Object.const_defined?("SelinimumFoo")).to be true
          expect(Object.const_defined?("SelinimumBar")).to be true
        end

        it "temporarily resets nested sibling autoloads" do
          cache_constants("SelinimumTopLevel") do
            SelinimumTopLevel = Class.new

            cache_constants("SelinimumFoo") do
              SelinimumFoo = Class.new
            end

            cache_constants("SelinimumBar") do
              expect(Object.const_defined?("SelinimumFoo")).to be false
              SelinimumBar = Class.new
            end
            expect(Object.const_defined?("SelinimumFoo")).to be true
            expect(Object.const_defined?("SelinimumBar")).to be true
          end
        end

        # this will require some refactoring...
        it "temporarily resets outer autoloads" do
          pending "not implemented"

          cache_constants("SelinimumFoo") do
            SelinimumTopLevel = Class.new

            cache_constants("SelinimumBar") do
              expect(Object.const_defined?("SelinimumFoo")).to be false
              SelinimumFoo = Class.new
            end
          end

          expect(Object.const_defined?("SelinimumFoo")).to be true
          expect(Object.const_defined?("SelinimumBar")).to be true
        end

        it "doesn't reset autoloads from surrounding modules" do
          cache_constants("SelinimumFoo") do
            SelinimumFoo = Class.new
          end

          cache_constants("SelinimumFoo::Baz") do
            expect(Object.const_defined?("SelinimumFoo")).to be true
            SelinimumFoo::Baz = Class.new
          end

          expect(Object.const_defined?("SelinimumFoo")).to be true
          expect(Object.const_defined?("SelinimumFoo::Baz")).to be true
        end

        it "restores dependencies" do
          cache_constants("SelinimumFoo") do
            SelinimumFoo = Class.new

            cache_constants("SelinimumBar") do
              SelinimumBar = Class.new
            end
          end

          subject.reset_autoloads!
          cache_constants("SelinimumFoo")

          expect(Object.const_defined?("SelinimumFoo")).to be true
          expect(Object.const_defined?("SelinimumBar")).to be true
        end
      end
    end

    context "with a corresponding cached autoload" do
      before do
        cache_constants do
          SelinimumFoo = Class.new
          "lol"
        end
      end

      it "caches on subsequent calls" do
        count = 0
        2.times do
          cache_constants { count += 1 }
        end
        expect(count).to eq 0
      end

      it "returns the cached block expression" do
        expect(cache_constants { "wtf" }).to eql("lol")
      end

      it "restores it when nested in an as-yet-uncached call" do
        og_const = SelinimumFoo
        subject.reset_autoloads!

        cache_constants "SelinimumBar" do
          SelinimumBar = Class.new
          cache_constants { }
        end

        expect(SelinimumFoo).to eql(og_const)
      end
    end
  end

  describe ".reset_autoloads!" do
    it "hides currently cached autoloads" do
      cache_constants { SelinimumFoo = Class.new }
      subject.reset_autoloads!
      expect(Object.const_defined?("SelinimumFoo")).to be false
    end

    it "leaves other constants alone" do
      LeaveBritneyAlone = Class.new
      subject.reset_autoloads!
      expect(Object.const_defined?("LeaveBritneyAlone")).to be true
    end

    it "handles uncached reflections" do
      SomeModel = Class.new(ActiveRecord::Base) do
        belongs_to :selinimum_bar
      end
      subject.reset_autoloads!
      expect(SomeModel.reflections["selinimum_foo"].instance_variable_get(:@klass)).to be_nil
    end

    it "resets cached reflections" do
      AnotherModel = Class.new(ActiveRecord::Base) do
        belongs_to :selinimum_foo
      end
      cache_constants do
        SelinimumFoo = Class.new(ActiveRecord::Base)
        expect(AnotherModel.reflections["selinimum_foo"].klass).to eq SelinimumFoo
      end
      subject.reset_autoloads!
      expect(AnotherModel.reflections["selinimum_foo"].instance_variable_get(:@klass)).to be_nil
    end
  end

  after do
    subject.reset_autoloads!
    subject.cached_autoloads.clear
    subject.remove_instance_variable(:@preloaded_models)
  end
end
