$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'pry' if ENV['APP_ENV'] == 'debug' # add `binding.pry` wherever you need to debug
require 'mountaineer'
require 'magazine'
require 'issue'
require 'constituent'
require 'contributor'
require 'contribution'
