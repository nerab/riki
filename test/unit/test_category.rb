require File.join(File.dirname(__FILE__), '..', 'helper')

class TestCategory < Test::Unit::TestCase
  include RikiTest

  def test_single
    vienna = mocked('test_single'){Riki::Category.find_by_title('Vienna').first}
    members = mocked('test_single_members'){vienna.members}

    assert_equal(18, members.size)
    assert_equal('Vienna', members.first.title)
    assert_equal(Riki::Page, members.first.class)
    members[1..-1].each do |cat|
      assert_equal(Riki::Category, cat.class)
    end
  end
end
