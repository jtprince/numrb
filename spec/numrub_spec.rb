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

describe "Numrub with a simple numerical array" do
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
