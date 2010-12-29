require 'test_helper'

class TidesControllerTest < ActionController::TestCase
  test "should get predict" do
    get :predict
    assert_response :success
  end

end
