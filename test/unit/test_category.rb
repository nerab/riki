require File.join(File.dirname(__FILE__), '..', 'helper')

class TestCategory < Test::Unit::TestCase
  include RikiTest

  def test_single
    vienna = mocked('test_single'){Riki::Category.find_by_title('Vienna').first}
    assert_equal(18, vienna.members.size)
 
    # TODO Implement
#    assert_equal('Ruby', page.title)
#    assert_contains('gem', page.content)
#    assert_equal(43551, page.id)
#    assert_equal('0', page.namespace)
#    assert_equal(DateTime.parse(Time.at(1334345082).to_s), page.last_modified)
  end
end
