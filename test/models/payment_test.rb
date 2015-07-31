require 'test_helper'

class PaymentTest < ActiveSupport::TestCase

  def setup
    @payment = Payment.new
    @payment.save
  end

  def teardown
    @payment.destroy
  end

  test "the truth" do
    assert true
  end

  test "payment method" do
  	assert Constants.PaymentMethodValues.include?(@payment.method)
  end
end
