require 'test_helper'

# Unit tests for module Sale
module Sale
  describe 'Campaign' do
    let(:campaign) { Sale::Campaign.new }

    it 'must be valid' do
      value(campaign).must_be :valid?
    end
  end

  describe 'Package' do
    let(:sale_package) { Sale::Package.new }

    it 'must be valid' do
      value(sale_package).must_be :valid?
    end
  end

  describe 'Course' do
    let(:sale_course) { Sale::Course.new }

    it 'must be valid' do
      value(sale_course).must_be :valid?
    end
  end
end
