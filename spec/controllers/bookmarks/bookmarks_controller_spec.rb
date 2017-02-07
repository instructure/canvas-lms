require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Bookmarks::BookmarksController do
  context "when user is not logged in" do
    it "should fail" do
      get 'index', format: 'json'
      assert_status(401)
    end
  end

  context "when user is logged in" do
    let(:u) { user_factory }
    let!(:bookmark) { Bookmarks::Bookmark.create(user_id: u.id, name: 'bio 101', url: '/courses/1') }

    before(:each) do
      user_session(u)
    end

    describe "GET 'index'" do
      it "should succeed" do
        get 'index', format: 'json'
        expect(response).to be_success
      end
    end

    describe "GET 'show'" do
      it "should succeed" do
        get 'show', id: bookmark.id, format: 'json'
        expect(response).to be_success
      end

      it "includes data" do
        bookmark.update_attributes(data: {foo: "bar"})
        get 'show', id: bookmark.id, format: 'json'
        json = json_parse
        expect(json["data"]["foo"]).to eq("bar")
      end

      it "restricts to own bookmarks" do
        u2 = user_factory
        bookmark2 = Bookmarks::Bookmark.create(user_id: u2.id, name: 'bio 101', url: '/courses/1')
        get 'show', id: bookmark2.id, format: 'json'
        expect(response).to_not be_success
      end
    end

    describe "POST 'create'" do
      let(:params) { { name: 'chem 101', url: '/courses/2', format: 'json' } }

      it "should succeed" do
        post 'create', params
        expect(response).to be_success
      end

      it "should create a bookmark" do
        expect { post 'create', params }.to change { Bookmarks::Bookmark.count }.by(1)
      end

      it "should set user" do
        post 'create', params
        expect(Bookmarks::Bookmark.order(:id).last.user_id).to eq(u.id)
      end

      it "should set data" do
        post 'create', params.merge(data: {foo: "bar"})
        expect(Bookmarks::Bookmark.order(:id).last.data["foo"]).to eq("bar")
      end

      it "should append by default" do
        post 'create', params
        expect(Bookmarks::Bookmark.order(:id).last).to be_last
      end

      it "should set position" do
        post 'create', params.merge(position: 1)
        expect(Bookmarks::Bookmark.order(:id).last).to_not be_last
      end

      it "should handle position strings" do
        post 'create', params.merge(position: "1")
        expect(Bookmarks::Bookmark.order(:id).last).to_not be_last
      end
    end

    describe "PUT 'update'" do
      it "should succeed" do
        put 'update', id: bookmark.id, format: 'json'
        expect(response).to be_success
      end
    end

    describe "DELETE 'delete'" do
      it "should succeed" do
        delete 'destroy', id: bookmark.id, format: 'json'
        expect(response).to be_success
      end
    end
  end
end
