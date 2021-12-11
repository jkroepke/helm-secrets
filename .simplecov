require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

SimpleCov.start do
  minimum_coverage 5
  add_filter "/contrib/"
  add_filter "/examples/"
  add_filter "/lib/file/helm-values-getter/"
  add_filter "/tests/"
  add_filter "/.git/"
  add_filter "/tmp/"
end
