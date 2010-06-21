require 'rubygems'
require 'rake'
require 'jeweler'
require 'rcov/rcovtask'
require 'rake/rdoctask'

Jeweler::Tasks.new do |gem|
  gem.name = "numrb"
  gem.summary = "numeric arrays built on FFI::Inliner so you can easily incorporate C manipulations"
  gem.description = "numeric arrays built on FFI::Inliner so you can easily incorporate C manipulations.  Supports basic operations."
  gem.email = "jtprince@gmail.com"
  gem.homepage = "http://github.com/jtprince/numrb"
  gem.authors = ["John Prince"]
  gem.add_development_dependency "spec-more", ">= 0"
end
Jeweler::GemcutterTasks.new

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

task :default => :spec

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "numrb #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
