require 'bundler'
Bundler::GemHelper.install_tasks

begin

  require 'rspec'
  require 'rspec/core/rake_task'
  
  
  desc  "Run RSpec code examples"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rcov = true
    t.rcov_opts = %w{--exclude osx\/objc,gems\/,spec\/,features\/}
  end

rescue LoadError => e
  puts e
end