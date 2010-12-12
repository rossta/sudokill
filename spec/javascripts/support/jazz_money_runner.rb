require 'rubygems'
require 'jazz_money'
require 'yaml'

code = []
specs = []

jasmine_yml = File.open('spec/javascripts/support/jasmine.yml')
config = YAML::load_stream(jasmine_yml).documents[0]

# parse jasmine config file to get code and specs to run

JazzMoney::Runner.new(code, specs).call