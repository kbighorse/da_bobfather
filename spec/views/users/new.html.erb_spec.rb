require 'spec_helper'

describe "users/new" do
  before(:each) do
    assign(:user, stub_model(User,
      :name => "MyString",
      :email => "MyString",
      :fbid => "MyString",
      :registered => false,
      :fb_access_token => "MyString",
      :favorite_donut => "MyString",
      :state => "MyString",
      :is_bobfather => false
    ).as_new_record)
  end

  it "renders new user form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => users_path, :method => "post" do
      assert_select "input#user_name", :name => "user[name]"
      assert_select "input#user_email", :name => "user[email]"
      assert_select "input#user_fbid", :name => "user[fbid]"
      assert_select "input#user_registered", :name => "user[registered]"
      assert_select "input#user_fb_access_token", :name => "user[fb_access_token]"
      assert_select "input#user_favorite_donut", :name => "user[favorite_donut]"
      assert_select "input#user_state", :name => "user[state]"
      assert_select "input#user_is_bobfather", :name => "user[is_bobfather]"
    end
  end
end
