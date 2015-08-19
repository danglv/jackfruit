require 'test_helper'
require 'json'

class FakePaymentController < ApplicationController
  include PaymentServices
end

class FakePaymentControllerTest < ActionController::TestCase
  def setup
    @baokim = FakePaymentController::BaoKimPaymentPro.new
  end

  def teardown
    @baokim = nil
  end
  
  test 'should have BaoKimPayment declared' do
    assert @baokim
  end
end