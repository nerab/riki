require File.join(File.dirname(__FILE__), '..', 'helper')

class TestTypeRegistry < Test::Unit::TestCase
  include RikiTest
  include Riki

  def test_page
    assert_equal(Page, TypeRegistry.get('page'))
    assert_equal(Page, TypeRegistry.get(:page))
  end

  def test_category
    assert_equal(Category, TypeRegistry.get('category'))
    assert_equal(Category, TypeRegistry.get(:category))
  end

  def test_sub_category
    assert_equal(Category, TypeRegistry.get('subcat'))
    assert_equal(Category, TypeRegistry.get(:subcat))
  end

  def test_undefined
    assert_raises(NoMethodError) do
      TypeRegistry.get('undefined')
    end
    
    assert_raises(NoMethodError) do
      TypeRegistry.get(:undefined)
    end
  end
end