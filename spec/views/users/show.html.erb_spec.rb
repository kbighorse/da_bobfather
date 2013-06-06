require 'spec_helper'

describe "users/show" do
  before(:each) do
    @user = assign(:user, stub_model(User,
      :name => "Name",
      :email => "Email",
      :fbid => "Fbid",
      :registered => false,
      :fb_access_token => "Fb Access Token",
      :favorite_donut => "Favorite Donut",
      :state => "State",
      :is_bobfather => false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Email/)
    rendered.should match(/Fbid/)
    rendered.should match(/false/)
    rendered.should match(/Fb Access Token/)
    rendered.should match(/Favorite Donut/)
    rendered.should match(/State/)
    rendered.should match(/false/)
  end
end
