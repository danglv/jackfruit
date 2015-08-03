require 'test_helper'

class FakePaymentController < ApplicationController
  include PaymentServices
end

class FakePaymentControllerTest < ActionController::TestCase
  def setup
    @baokim = FakePaymentController::BaoKimPayment.new
  end

  def teardown
    @baokim = nil
  end
  
  test 'should have BaoKimPayment declared' do
    assert @baokim
  end

  test 'should have function create_request_url that accepts a hash as argument' do
    assert @baokim.create_request_url({
      'order_id' =>  '',
      'business' =>  '',
      'total_amount' =>  '',
      'shipping_fee' =>  '',
      'tax_fee' =>  '',
      'order_description' =>  '',
      'url_success' =>  '',
      'url_cancel' =>  '',
      'url_detail' =>  ''
    })
  end

  test 'create_request_url should return an url which has one question mark' do
    params = {
      'order_id' =>  '',
      'business' =>  '',
      'total_amount' =>  '',
      'shipping_fee' =>  '',
      'tax_fee' =>  '',
      'order_description' =>  '',
      'url_success' =>  '',
      'url_cancel' =>  '',
      'url_detail' =>  ''
    }

    url = @baokim.create_request_url(params)

    assert_equal  1, url.count('?')
  end

  test 'create_request_url should return an url which is formatted' do
    params = {
      'order_id' =>  1,
      'business' =>  'ngoc.phungba@gmail.com',
      'total_amount' =>  1,
      'shipping_fee' =>  0,
      'tax_fee' =>  0,
      'order_description' =>  '',
      'url_success' =>  '',
      'url_cancel' =>  '',
      'url_detail' =>  ''
    }

    url = @baokim.create_request_url(params)

    assert url.index('merchant_id') > 0
    assert url.index('business=ngoc.phungba@gmail.com') > 0
    assert url.index('92F225C50E447B66F65531F8F43BACB5') > 0
  end

  test 'verify_response_url should be truthy with same params' do
    params = {
      'merchant_id' => '18578',
      'order_id' =>  1,
      'business' =>  'ngoc.phungba@gmail.com',
      'total_amount' =>  1,
      'shipping_fee' =>  0,
      'tax_fee' =>  0,
      'order_description' =>  '',
      'url_success' =>  '',
      'url_cancel' =>  '',
      'url_detail' =>  '',
      'checksum' => '92F225C50E447B66F65531F8F43BACB5'
    }

    assert @baokim.verify_response_url(params)    
  end
end