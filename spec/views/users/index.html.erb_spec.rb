require 'spec_helper'

describe "users/index" do
  before(:each) do
    assign(:users, [
      stub_model(User,
        :name => "Name",
        :email => "Email",
        :fbid => "Fbid",
        :registered => false,
        :fb_access_token => "Fb Access Token",
        :favorite_donut => "Favorite Donut",
        :state => "State",
        :is_bobfather => false
      ),
      stub_model(User,
        :name => "Name",
        :email => "Email",
        :fbid => "Fbid",
        :registered => false,
        :fb_access_token => "Fb Access Token",
        :favorite_donut => "Favorite Donut",
        :state => "State",
        :is_bobfather => false
      )
    ])
  end

  it "renders a list of users" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Email".to_s, :count => 2
    assert_select "tr>td", :text => "Fbid".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
    assert_select "tr>td", :text => "Fb Access Token".to_s, :count => 2
    assert_select "tr>td", :text => "Favorite Donut".to_s, :count => 2
    assert_select "tr>td", :text => "State".to_s, :count => 2
    assert_select "tr>td", :text => false.to_s, :count => 2
  end
end
