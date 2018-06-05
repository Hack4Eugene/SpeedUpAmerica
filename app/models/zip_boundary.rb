class ZipBoundary < ActiveRecord::Base
  serialize :bounds, Array
end
