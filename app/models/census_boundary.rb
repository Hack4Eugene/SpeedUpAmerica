class CensusBoundary < ActiveRecord::Base
  serialize :bounds, Array
end
