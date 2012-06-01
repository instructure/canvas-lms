#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Collections API", :type => :integration do
  shared_examples_for "full access to collections" do
    it "should allow retrieving a paginated collection list" do
      json = api_call(:get, @collections_path, @collections_path_options)
      response['Link'].should be_present
      json.should == [ @c2_json, @c1_json ]
    end

    it "should allow retrieving a private collection" do
      json = api_call(:get, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "show", :format => "json" })
      json.should == @c1_json
    end

    it "should allow creating a collection" do
      json = api_call(:post, @collections_path, @collections_path_options.merge(:action => "create"), {
        :name => "test3",
        :visibility => 'public',
      })
      @c3 = Collection.last(:order => :id)
      json.should == {
        'id' => @c3.id,
        'name' => 'test3',
        'visibility' => 'public',
        'followed_by_user' => false,
      }
    end

    it "should allow updating a collection" do
      json = api_call(:put, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "update", :format => "json" }, {
        :name => "test1 edited",
      })
      json.should == @c1_json.merge('name' => 'test1 edited')
      @c1.reload.name.should == "test1 edited"
    end

    it "should allow changing private to public but not the reverse" do
      json = api_call(:put, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "update", :format => "json" }, {
        :name => "test1 edited",
        :visibility => "public",
      })
      @c1.reload
      @c1.name.should == "test1 edited"
      @c1.visibility.should == "public"

      json = api_call(:put, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "update", :format => "json" }, {
        :visibility => "private",
      }, {}, :expected_status => 400)
      @c1.reload
      @c1.name.should == "test1 edited"
      @c1.visibility.should == "public"
    end

    it "should allow deleting a collection" do
      json = api_call(:delete, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "destroy", :format => "json" })
      @c1.reload.state.should == :deleted
    end

    context "deleted collection" do
      before do
        @c1.destroy
      end

      it "should not return in list" do
        json = api_call(:get, @collections_path, @collections_path_options)
        json.should == [ @c2_json ]
      end

      it "should not allow getting" do
        json = api_call(:get, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "show", :format => "json" }, {}, {}, :expected_status => 404)
      end
    end
  end

  shared_examples_for "public only access to collections" do
    before do
      user_with_pseudonym
    end

    it "should only list public collections" do
      json = api_call(:get, @collections_path, @collections_path_options)
      response['Link'].should be_present
      json.should == [ @c2_json ]
    end

    it "should allow getting a public collection" do
      json = api_call(:get, "/api/v1/collections/#{@c2.id}", { :controller => "collections", :collection_id => @c2.to_param, :action => "show", :format => "json" })
      json.should == @c2_json
    end

    it "should not allow getting a private collection" do
      json = api_call(:get, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "show", :format => "json" }, {}, {}, :expected_status => 401)
      json['message'].should match /not authorized/
    end

    it "should not allow creating a collection" do
      expect {
        json = api_call(:post, @collections_path, @collections_path_options.merge(:action => "create"), {
          :name => "test3",
          :visibility => 'public',
        }, {}, :expected_status => 401)
      }.to change(CollectionItem, :count).by(0)
    end

    it "should not allow updating a collection" do
      json = api_call(:put, "/api/v1/collections/#{@c2.id}", { :controller => "collections", :collection_id => @c2.to_param, :action => "update", :format => "json" }, {
        :name => "test2 edited",
      }, {}, :expected_status => 401)
      @c2.reload.name.should == "test2"
    end

    it "should not allow deleting a collection" do
      json = api_call(:delete, "/api/v1/collections/#{@c2.id}", { :controller => "collections", :collection_id => @c2.to_param, :action => "destroy", :format => "json" }, {}, {}, :expected_status => 401)
      @c2.reload.should be_active
    end
  end

  def create_collections(context)
    @c1 = context.collections.create!(:name => 'test1', :visibility => 'private')
    @c2 = context.collections.create!(:name => 'test2', :visibility => 'public')
    @c1_json =
      {
        'id' => @c1.id,
        'name' => @c1.name,
        'visibility' => 'private',
        'followed_by_user' => false,
      }
    @c2_json = 
      {
        'id' => @c2.id,
        'name' => @c2.name,
        'visibility' => 'public',
        'followed_by_user' => false,
      }
  end

  def create_collection_items(user)
    @i1 = collection_item_model(:user_comment => "item 1", :user => user, :collection => @c1, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/one"))
    @i2 = collection_item_model(:user_comment => "item 2", :user => user, :collection => @c1, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/two"))
    @i3 = collection_item_model(:user_comment => "item 3", :user => user, :collection => @c2, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/three"))
    @unscoped_items_path = "/api/v1/collections/items"
    @c1_items_path = "/api/v1/collections/#{@c1.id}/items"
    @c2_items_path = "/api/v1/collections/#{@c2.id}/items"
    @unscoped_items_path_options = { :controller => "collection_items", :action => "index", :format => "json" }
    @c1_items_path_options = { :controller => "collection_items", :action => "index", :format => "json", :collection_id => @c1.to_param }
    @c2_items_path_options = { :controller => "collection_items", :action => "index", :format => "json", :collection_id => @c2.to_param }
  end

  def item_json(item, upvoted_by_user = false)
    {
      'id' => item.id,
      'collection_id' => item.collection_id,
      'user' => {
        'id' => item.user.id,
        'display_name' => item.user.short_name,
        'avatar_image_url' => "http://www.example.com/images/users/#{User.avatar_key(item.user.id)}",
        'html_url' => (item.user == @user) ? "http://www.example.com/profile" : "http://www.example.com/users/#{item.user.id}",
      },
      'item_type' => item.collection_item_data.item_type,
      'link_url' => item.collection_item_data.link_url,
      'post_count' => item.collection_item_data.post_count,
      'upvote_count' => item.collection_item_data.upvote_count,
      'upvoted_by_user' => upvoted_by_user,
      'root_item_id' => item.collection_item_data.root_item_id,
      'image_url' => item.data.image_attachment && "http://www.example.com/images/thumbnails/#{item.data.image_attachment.id}/#{item.data.image_attachment.uuid}?size=640x%3E",
      'image_pending' => item.data.image_pending,
      'html_preview' => item.data.html_preview,
      'user_comment' => item.user_comment,
      'url' => "http://www.example.com/api/v1/collections/items/#{item.id}",
      'created_at' => item.created_at.iso8601,
      'description' => item.data.description,
      'title' => item.data.title,
    }
  end

  context "user scoped collections" do
    before do
      user_with_pseudonym
      @collections_path = "/api/v1/users/#{@user.id}/collections"
      @collections_path_options = { :controller => "collections", :action => "index", :format => "json", :user_id => @user.to_param }
      create_collections(@user)
    end

    context "a user's own collections" do
      it_should_behave_like "full access to collections"

      it "should create a default private collection if no collections exist for the context" do
        @empty_user = user_with_pseudonym
        @user = @empty_user
        json = api_call(:get, "/api/v1/users/#{@empty_user.id}/collections", { :controller => "collections", :action => "index", :format => "json", :user_id => @empty_user.to_param })
        response['Link'].should be_present
        json.should_not be_empty
        json.first['visibility'].should == 'private'
      end
    end

    context "another user's collections" do
      it_should_behave_like "public only access to collections"
    end

    it "should not allow following your own collection" do
      json = api_call(:put, "/api/v1/collections/#{@c2.id}/followers/self", { :controller => "collections", :collection_id => @c2.to_param, :action => "follow", :format => "json" }, {}, {}, :expected_status => 400)
      @user.reload.user_follows.should == []
    end

    describe "Collection Items" do
      before do
        create_collection_items(@user)
        @user1 = @user
        user_with_pseudonym
        @user2 = @user
        @user = @user1
        @c3 = @user2.collections.create!(:name => 'user2', :visibility => 'public')
        @i4 = collection_item_model(:user_comment => "cloned item 3", :user => @c3.context, :collection => @c3, :collection_item_data => @i3.collection_item_data); @i3.reload
        @items3_path = "/api/v1/collections/#{@c3.id}/items"
        @items3_path_options = { :controller => "collection_items", :action => "index", :format => "json", :collection_id => @c3.to_param }
      end

      it "should allow retrieving a pagniated item list from a private collection" do
        json = api_call(:get, @c1_items_path, @c1_items_path_options)
        response['Link'].should be_present
        json.should == [ item_json(@i2), item_json(@i1) ]
      end

      describe "item creation" do
        it "should allow creating from a http url" do
          json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
          new_item = @c1.collection_items.last(:order => :id)
          new_item.collection_item_data.link_url.should == "http://www.example.com/a/b/c"
          new_item.user.should == @user
        end

        it "should allow cloning an existing item" do
          json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://localhost/api/v1/collections/items/#{@i3.id}", :user_comment => 'cloned' })
          json['post_count'].should == 3
          new_item = @c1.collection_items.last(:order => :id)
          new_item.collection_item_data.should == @i3.collection_item_data
          new_item.user.should == @user
        end

        it "should not allow cloning an item the user can't access" do
          @user = @user2
          expect {
            json = api_call(:post, @items3_path, @items3_path_options.merge(:action => "create"), { :link_url => "http://localhost/api/v1/collections/items/#{@i1.id}", :user_comment => 'cloned' }, {}, :expected_status => 401)
          }.to change(CollectionItem, :count).by(0)
        end

        it "should reject non-http urls" do
          expect {
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "javascript:alert(1)", :user_comment => 'new item' }, {}, :expected_status => 400)
          }.to change(CollectionItem, :count).by(0)
        end

        describe "images" do
          it "should take a snapshot of the link url if no image is provided and there is no embedly image" do
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            @item = CollectionItem.find(json['id'])
            @item.data.image_pending.should == true
            @att = Attachment.new(:uploaded_data => stub_png_data)
            CutyCapt.expects(:snapshot_attachment_for_url).with(@item.data.link_url).returns(@att)
            run_job()

            @att.reload.context.should == Account.default

            @item.reload.data.image_pending.should == false
            @item.data.image_attachment.should == @att

            json = api_call(:get, "#{@unscoped_items_path}/#{@item.id}", @unscoped_items_path_options.merge(:item_id => @item.to_param, :action => "show"))
            json['image_pending'].should == false
            json['image_url'].should == "http://www.example.com/images/thumbnails/#{@att.id}/#{@att.uuid}?size=640x%3E"
          end

          it "should clone and use the image if provided" do
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :image_url => "http://www.example.com/my/image.png", :user_comment => 'new item' })
            @item = CollectionItem.find(json['id'])
            @item.data.image_pending.should == true
            http_res = mock('Net::HTTPOK', :body => File.read(Rails.root+"public/images/cancel.png"), :code => 200)
            Canvas::HTTP.expects(:get).with("http://www.example.com/my/image.png").returns(http_res)
            run_job()

            @item.reload.data.image_pending.should == false
            @att = @item.data.image_attachment
            @att.should be_present
            @att.context.should == Account.default

            json = api_call(:get, "#{@unscoped_items_path}/#{@item.id}", @unscoped_items_path_options.merge(:item_id => @item.to_param, :action => "show"))
            json['image_pending'].should == false
            json['image_url'].should == "http://www.example.com/images/thumbnails/#{@att.id}/#{@att.uuid}?size=640x%3E"
          end

          it "should use the embedly image if no image is provided" do
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            @item = CollectionItem.find(json['id'])
            @item.data.image_pending.should == true
            Canvas::Embedly.any_instance.expects(:get_embedly_data).with("http://www.example.com/a/b/c").returns(stub_everything('embedly api', :type => 'test', :images => [{'url' => 'http://www.example.com/image1'}], :html => "<iframe>test</iframe>"))
            http_res = mock('Net::HTTPOK', :body => File.read(Rails.root+"public/images/cancel.png"), :code => 200)
            Canvas::HTTP.expects(:get).with("http://www.example.com/image1").returns(http_res)
            run_job()

            @item.reload.data.image_pending.should == false
            @att = @item.data.image_attachment
            @att.should be_present
            @att.context.should == Account.default

            @item.data.html_preview.should == "<iframe>test</iframe>"

            json = api_call(:get, "#{@unscoped_items_path}/#{@item.id}", @unscoped_items_path_options.merge(:item_id => @item.to_param, :action => "show"))
            json['image_pending'].should == false
            json['image_url'].should == "http://www.example.com/images/thumbnails/#{@att.id}/#{@att.uuid}?size=640x%3E"
          end
        end

        describe "embedly data" do
          it "should use the embeldy description and title if none are given" do
            Canvas::Embedly.any_instance.stubs(:get_embedly_data).with("http://www.example.com/a/b/c").returns(stub_everything('embedly api', :type => 'html', :description => 'e desc', :title => 'e title'))
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            run_job()
            CollectionItem.find(json['id']).data.attributes.slice('title', 'description').should == { 'title' => "e title", 'description' => "e desc" }

            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item', :title => "custom title" })
            run_job()
            CollectionItem.find(json['id']).data.attributes.slice('title', 'description').should == { 'title' => "custom title", 'description' => "e desc" }

            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item', :description => "custom description" })
            run_job()
            CollectionItem.find(json['id']).data.attributes.slice('title', 'description').should == { 'title' => "e title", 'description' => "custom description" }
          end

          it "should use the embedly item type if valid" do
            Canvas::Embedly.any_instance.stubs(:get_embedly_data).with("http://www.example.com/a/b/c").returns(stub_everything('embedly api', :type => 'video'))
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            run_job()
            CollectionItem.find(json['id']).data.item_type.should == 'video'

            Canvas::Embedly.any_instance.stubs(:get_embedly_data).with("http://www.example.com/a/b/c").returns(stub_everything('embedly api', :type => 'rtf'))
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            run_job()
            CollectionItem.find(json['id']).data.item_type.should == 'url'
          end

          it "should only allow iframe embeds" do
            iframe_html =  "<iframe src='http://example.com/'></iframe>"
            div_html = "<div class='blah'><p>text</p></div>"

            Canvas::Embedly.any_instance.expects(:get_embedly_data).with("http://www.example.com/a/b/c").returns(stub_everything('embedly api', :type => 'html', :html => iframe_html))
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            run_job()
            CollectionItem.find(json['id']).data.html_preview.should == iframe_html

            Canvas::Embedly.any_instance.expects(:get_embedly_data).with("http://www.example.com/a/b/c").returns(stub_everything('embedly api', :type => 'html', :html => div_html))
            json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
            run_job()
            CollectionItem.find(json['id']).data.html_preview.should be_blank
          end
        end
      end

      it "should allow editing mutable fields" do
        json = api_call(:put, "#{@unscoped_items_path}/#{@i1.id}", @unscoped_items_path_options.merge(:item_id => @i1.to_param, :action => "update"), {
          :user_comment => "modified",
          :link_url => 'cant change',
          :item_type => 'cant change',
          :image_url => "http://www.example.com/cant_change"
        })
        json.should == item_json(@i1.reload)
        @i1.user_comment.should == "modified"
        @i1.collection_item_data.item_type.should == "url"
        @i1.data.image_pending.should == false
      end

      it "should allow deleting an owned item" do
        json = api_call(:delete, "#{@unscoped_items_path}/#{@i1.id}", @unscoped_items_path_options.merge(:item_id => @i1.to_param, :action => "destroy"))
        @i1.reload.state.should == :deleted
      end

      it "should not allow getting from a deleted collection" do
        @i1.collection.destroy
        # deleting the collection doesn't mark all the items as deleted, though
        # they can't be retrieved through the api
        # this makes undeleting work better
        @i1.reload.should be_active
        json = api_call(:get, "#{@unscoped_items_path}/#{@i1.id}", @unscoped_items_path_options.merge(:item_id => @i1.to_param, :action => "show"), {}, {}, :expected_status => 404)
      end

      context "deleted item" do
        before do
          @i1.destroy
        end

        it "should not return in the list" do
          json = api_call(:get, @c1_items_path, @c1_items_path_options)
          json.should == [ item_json(@i2) ]
        end

        it "should not allow getting" do
          json = api_call(:get, "#{@unscoped_items_path}/#{@i1.id}", @unscoped_items_path_options.merge(:item_id => @i1.to_param, :action => "show"), {}, {}, :expected_status => 404)
        end
      end

      context "another user's collections" do
        before do
          user_with_pseudonym
        end

        it "should not allow listing from a private collection" do
          json = api_call(:get, @c1_items_path, @c1_items_path_options, {}, {}, :expected_status => 401)
        end

        it "should allow listing a public collection" do
          json = api_call(:get, @c2_items_path, @c2_items_path_options)
          response['Link'].should be_present
          json.should == [ item_json(@i3) ]
        end
      end

      context "upvoting" do
        it "should allow upvoting an item" do
          @user = @user2
          json = api_call(:put, "#{@unscoped_items_path}/#{@i3.id}/upvotes/self", @unscoped_items_path_options.merge(:action => "upvote", :item_id => @i3.to_param))
          json.slice('item_id', 'root_item_id', 'user_id').should == {
            'item_id' => @i3.id,
            'root_item_id' => @i3.id,
            'user_id' => @user.id,
          }
          @i3.reload.collection_item_data.upvote_count.should == 1

          # upvoting again is a no-op
          json = api_call(:put, "#{@unscoped_items_path}/#{@i3.id}/upvotes/self", @unscoped_items_path_options.merge(:action => "upvote", :item_id => @i3.to_param))
          json.slice('item_id', 'root_item_id', 'user_id').should == {
            'item_id' => @i3.id,
            'root_item_id' => @i3.id,
            'user_id' => @user.id,
          }
          @i3.reload.collection_item_data.upvote_count.should == 1
        end

        it "should not allow upvoting a non-visible item" do
          @user = @user2
          json = api_call(:put, "#{@unscoped_items_path}/#{@i1.id}/upvotes/self", @unscoped_items_path_options.merge(:action => "upvote", :item_id => @i1.to_param), {}, {}, :expected_status => 401)
          @i1.reload.collection_item_data.upvote_count.should == 0
        end
      end

      context "de-upvoting" do
        before do
          @user = @user2
        end

        it "should allow removing an upvote" do
          @i3.collection_item_data.collection_item_upvotes.create!(:user => @user)
          @i3.reload.collection_item_data.upvote_count.should == 1
          json = api_call(:delete, "#{@unscoped_items_path}/#{@i3.id}/upvotes/self", @unscoped_items_path_options.merge(:action => "remove_upvote", :item_id => @i3.to_param))
          @i3.reload.collection_item_data.upvote_count.should == 0
        end

        it "should ignore if the user hasn't upvoted the item" do
          json = api_call(:delete, "#{@unscoped_items_path}/#{@i3.id}/upvotes/self", @unscoped_items_path_options.merge(:action => "remove_upvote", :item_id => @i3.to_param))
        end
      end
    end
  end

  context "group scoped collections" do
    before do
      user_with_pseudonym
      group_model({:group_category => GroupCategory.communities_for(Account.default), :is_public => true})
      @collections_path = "/api/v1/groups/#{@group.id}/collections"
      @collections_path_options = { :controller => "collections", :action => "index", :format => "json", :group_id => @group.to_param }
      create_collections(@group)
    end

    context "a group's collections, as moderator" do
      before do
        @group_membership = @group.add_user(@user, 'accepted', true)
      end

      it_should_behave_like "full access to collections"
    end

    context "a group's collections, as member" do
      before do
        @group_membership = @group.add_user(@user, 'accepted', false)
      end

      it "should allow retrieving a paginated collection list" do
        json = api_call(:get, @collections_path, @collections_path_options)
        response['Link'].should be_present
        json.should == [ @c2_json, @c1_json ]
      end

      it "should create a default private collection if no collections exist for the context" do
        @empty_group = group_model({:group_category => GroupCategory.communities_for(Account.default), :is_public => true})
        @empty_group.add_user(@user, 'accepted')
        json = api_call(:get, "/api/v1/groups/#{@empty_group.id}/collections", { :controller => "collections", :action => "index", :format => "json", :group_id => @empty_group.to_param })
        response['Link'].should be_present
        json.should_not be_empty
        json.first['visibility'].should == 'private'
      end

      it "should allow retrieving a private collection" do
        json = api_call(:get, "/api/v1/collections/#{@c1.id}", { :controller => "collections", :collection_id => @c1.to_param, :action => "show", :format => "json" })
        json.should == @c1_json
      end

      it "should not allow creating a collection" do
        expect {
          json = api_call(:post, @collections_path, @collections_path_options.merge(:action => "create"), {
            :name => "test3",
            :visibility => 'public',
          }, {}, :expected_status => 401)
        }.to change(CollectionItem, :count).by(0)
      end

      it "should not allow updating a collection" do
        json = api_call(:put, "/api/v1/collections/#{@c2.id}", { :controller => "collections", :collection_id => @c2.to_param, :action => "update", :format => "json" }, {
          :name => "test2 edited",
        }, {}, :expected_status => 401)
        @c2.reload.name.should == "test2"
      end

      it "should not allow deleting a collection" do
        json = api_call(:delete, "/api/v1/collections/#{@c2.id}", { :controller => "collections", :collection_id => @c2.to_param, :action => "destroy", :format => "json" }, {}, {}, :expected_status => 401)
        @c2.reload.should be_active
      end
    end

    context "a group's collections, as a non-member" do
      it_should_behave_like "public only access to collections"
    end

    describe "following" do
      it "should allow following a public collection" do
        json = api_call(:put, "/api/v1/collections/#{@c2.id}/followers/self", { :controller => "collections", :collection_id => @c2.to_param, :action => "follow", :format => "json" })
        @user.user_follows.map(&:followed_item).should == [@c2]
        uf = @user.user_follows.first
        json.should == { "following_user_id" => @user.id, "followed_collection_id" => @c2.id, "created_at" => uf.created_at.as_json }
      end

      it "should do nothing if already following the collection" do
        @user.user_follows.create!(:followed_item => @c2)
        uf = @user.user_follows.first
        @user.user_follows.map(&:followed_item).should == [@c2]

        json = api_call(:put, "/api/v1/collections/#{@c2.id}/followers/self", { :controller => "collections", :collection_id => @c2.to_param, :action => "follow", :format => "json" })
        @user.reload.user_follows.map(&:followed_item).should == [@c2]
        json.should == { "following_user_id" => @user.id, "followed_collection_id" => @c2.id, "created_at" => uf.created_at.as_json }
      end

      it "should not allow following a private collection" do
        json = api_call(:put, "/api/v1/collections/#{@c1.id}/followers/self", { :controller => "collections", :collection_id => @c1.to_param, :action => "follow", :format => "json" }, {}, {}, :expected_status => 401)
        @user.reload.user_follows.should == []
      end
    end


    describe "unfollowing" do
      it "should allow unfollowing a collection" do
        @user.user_follows.create!(:followed_item => @c2)
        @user.reload.user_follows.map(&:followed_item).should == [@c2]

        json = api_call(:delete, "/api/v1/collections/#{@c2.id}/followers/self", { :controller => "collections", :collection_id => @c2.to_param, :action => "unfollow", :format => "json" })
        @user.reload.user_follows.should == []
      end

      it "should do nothing if not following" do
        @user.reload.user_follows.should == []
        json = api_call(:delete, "/api/v1/collections/#{@c2.id}/followers/self", { :controller => "collections", :collection_id => @c2.to_param, :action => "unfollow", :format => "json" })
        @user.reload.user_follows.should == []
      end
    end

    describe "Collection Items" do
      before do
        create_collection_items(@user)
        @user1 = @user
        @user2 = user_with_pseudonym
        @group_membership2 = @group.add_user(@user2)

        @i4 = collection_item_model(:user_comment => "item 4", :user => @user2, :collection => @c2, :collection_item_data => collection_item_data_model(:link_url => "http://www.example.com/three"))
      end

      context "as a group member" do
        before do
          @group_membership = @group.add_user(@user1, 'accepted', false)
          @group_membership2 = @group.add_user(@user2, 'accepted', false)
          @user = @user2
        end

        it "should allow creating a new item" do
          json = api_call(:post, @c1_items_path, @c1_items_path_options.merge(:action => "create"), { :link_url => "http://www.example.com/a/b/c", :user_comment => 'new item' })
          new_item = @c1.collection_items.last(:order => :id)
          new_item.collection_item_data.link_url.should == "http://www.example.com/a/b/c"
          new_item.user.should == @user
        end

        it "should not allow updating an item created by someone else" do
          orig_user_comment = @i1.user_comment
          json = api_call(:put, "#{@unscoped_items_path}/#{@i1.id}", @unscoped_items_path_options.merge(:item_id => @i1.to_param, :action => "update"), {
            :user_comment => "item1 user_comment edited",
          }, {}, :expected_status => 401)
          @i1.reload.user_comment.should == orig_user_comment
        end

        it "should not allow deleting an item created by someone else" do
          json = api_call(:delete, "#{@unscoped_items_path}/#{@i1.id}", @unscoped_items_path_options.merge(:item_id => @i1.to_param, :action => "destroy"), {}, {}, :expected_status => 401)
          @i1.reload.should be_active
        end
      end

      context "as a group moderator" do
        before do
          @group_membership = @group.add_user(@user1, 'accepted', true)
          @group_membership2 = @group.add_user(@user2, 'accepted', false)
          @user = @user1
        end

        it "should allow updating an item created by someone else" do
          json = api_call(:put, "#{@unscoped_items_path}/#{@i4.id}", @unscoped_items_path_options.merge(:item_id => @i4.to_param, :action => "update"), { :user_comment => "modified" })
          json.should == item_json(@i4.reload)
          @i4.user_comment.should == "modified"
        end

        it "should allow deleting an item created by someone else" do
          json = api_call(:delete, "#{@unscoped_items_path}/#{@i4.id}", @unscoped_items_path_options.merge(:item_id => @i4.to_param, :action => "destroy"))
          @i4.reload.should be_deleted
        end
      end
    end
  end
end
