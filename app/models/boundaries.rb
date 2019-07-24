class Boundaries < ActiveRecord::Base
  self.primary_keys = :boundary_type, :boundary_id
end
