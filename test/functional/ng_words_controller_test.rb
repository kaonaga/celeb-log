require 'test_helper'

class NgWordsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ng_words)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ng_word" do
    assert_difference('NgWord.count') do
      post :create, :ng_word => { }
    end

    assert_redirected_to ng_word_path(assigns(:ng_word))
  end

  test "should show ng_word" do
    get :show, :id => ng_words(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => ng_words(:one).to_param
    assert_response :success
  end

  test "should update ng_word" do
    put :update, :id => ng_words(:one).to_param, :ng_word => { }
    assert_redirected_to ng_word_path(assigns(:ng_word))
  end

  test "should destroy ng_word" do
    assert_difference('NgWord.count', -1) do
      delete :destroy, :id => ng_words(:one).to_param
    end

    assert_redirected_to ng_words_path
  end
end
