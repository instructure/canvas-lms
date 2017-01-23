describe RuboCop::Cop::Migration::ModelBehavior do
  let(:config) {
    RuboCop::Config.new(
      "Migration/ModelBehavior" => {
        "Enabled" => true,
        "Included" => ["- db/migrate/*"],
        "Whitelist" => [
          "Migrations::FooFix",
          "*.update_all",
          "*.delete_all",
          "*.connection"
        ]
      }
    )
  }

  subject { described_class.new(config) }

  it "should find no offenses when calling whitelisted classes/methods" do
    inspect_source(subject, %{
      class Foo < ActiveRecord::Migration
        def up
          Migrations::FooFix.run
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling methods on whitelisted classes/methods" do
    inspect_source(subject, %{
      class Foo < ActiveRecord::Migration
        def up
          User.connection.execute "YOLO"
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling whitelisted methods" do
    inspect_source(subject, %{
      class Foo < ActiveRecord::Migration
        def up
          User.foo.bar.baz.update_all(name: "sally")
          Course.where(id: [1,2,3]).delete_all
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when calling receiver-less methods" do
    inspect_source(subject, %{
      class Foo < ActiveRecord::Migration
        module Lol
        end

        include Lol
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should find no offenses when referencing classes defined in the file itself" do
    inspect_source(subject, %{
      class User < ActiveRecord::Base; end
      Course = Class.new(ActiveRecord::Base)

      class Foo < ActiveRecord::Migration
        def up
          User.find_each { |u| u.save! }
          Course.find_each { |c| c.save! }
        end
      end
    })
    expect(subject.offenses.size).to eq(0)
  end

  it "should error if referencing unknown/auto-loaded classes" do
    inspect_source(subject, %{
      class Foo < ActiveRecord::Migration
        def up
          User.find_each { |u| u.save! }
          Course.where(id: [1,2,3]).find_each { |c| c.save! }
        end
      end
    })
    expect(subject.offenses.size).to eq(2)
    expect(subject.offenses.all? { |off| off.severity.name == :convention })
  end
end
