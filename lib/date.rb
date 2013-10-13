#!/usr/bin/ruby
require 'rubygems'
require 'chronic'

r = Chronic.parse(gets, :guess => false)
puts r.begin.to_i.to_s << '-' << r.end.to_i.to_s

#while s = gets do
#  puts Chronic.parse(s).to_i
#end

