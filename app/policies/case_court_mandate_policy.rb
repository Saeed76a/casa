class CaseCourtMandatePolicy < ApplicationPolicy
  alias_method :destroy?, :admin_or_supervisor?
end
