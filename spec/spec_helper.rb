require 'rubygems'
require 'spec/more'

Bacon.summary_on_exit

module Timer
  # returns whatever was in the block
  def self.measure(&block)
    start = Time.now
    block.call
    Time.now - start
  end
end
