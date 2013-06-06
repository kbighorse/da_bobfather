require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, user: { email: @user.email, favorite_donut: @user.favorite_donut, fb_access_token: @user.fb_access_token, fbid: @user.fbid, is_bobfather: @user.is_bobfather, last_login: @user.last_login, name: @user.name, registered: @user.registered, state: @user.state }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    put :update, id: @user, user: { email: @user.email, favorite_donut: @user.favorite_donut, fb_access_token: @user.fb_access_token, fbid: @user.fbid, is_bobfather: @user.is_bobfather, last_login: @user.last_login, name: @user.name, registered: @user.registered, state: @user.state }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
