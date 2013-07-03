# A sample Guardfile
# require "rubygem"
# require 'guard-bundler'
# require 'guard-rspec'
# require 'guard-livereload'

guard 'bundler' do
  watch('Gemfile')
end

guard 'rspec', :version => 2, :cli => '--color --format nested' do
  watch('app.rb')
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^\./(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
end

guard 'pow' do
  watch('.rvmrc')
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('app.rb')
  watch(%r{^spec/.+_spec\.rb$})
end
