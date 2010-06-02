require 'spec_helper'

require 'numrub'
require 'benchmark'

class Array
  # a fast sum implementation for arrays, I believe
  def sum
    sm = 0
    self.each {|v| sm += v }
    sm
  end
end

describe "initializing a Numrub" do
  it 'initializes with an array' do
    array = [1,2,3,4,5,6,7]
    x = Numrub::NumrubStruct.to_nr(array)
    ok x.is_a?(Object)
    x[:total].is array.size
    x[:rank].is 1
  end

  it 'can be passed out of a function as a pointer with FFI-Inliner' do
    array = [1,2,3,4,5,6,7]
    my_struct = Numrub::NumrubStruct.to_nr(array)
    Numrub.pass_out_as_pointer(my_struct).is my_struct.to_ptr
  end

  it 'must be cast after being passed out' do
    array = [1,2,3,4,5,6,7]
    my_struct = Numrub::NumrubStruct.to_nr(array)
    pointer = Numrub.pass_out_as_pointer(my_struct)
    object = Numrub::NumrubStruct.new(pointer)
    my_struct[:data].is object[:data]
    my_struct.class.is object.class
    my_struct.object_id.isnt object.object_id  # it is a new object (even though it points to the same data)
  end
end

xdescribe "Numrub with a simple numerical array" do
  before do
    @ar = [1,2,3,4,5]
    @nr = Numrub.new(@ar)  
  end

  it "sums" do
    @nr.sum.is 15
  end

  it "sums at least 50 times faster than a ruby array" do
    sz = 1000000
    ar = Array.new(sz, 2.0)
    nar = Numrub.new(ar) 
    (array_time, nub_time) = [ar, nar].map {|v| Timer.measure{ v.sum } }
    ok( (array_time / nub_time) > 50 )
  end

end
