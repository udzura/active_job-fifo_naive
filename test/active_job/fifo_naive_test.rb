# frozen_string_literal: true

require "test_helper"

class ActiveJob::FifoNaiveTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::ActiveJob::FifoNaive.const_defined?(:VERSION)
    end
  end
end
