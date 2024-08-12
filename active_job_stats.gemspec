Gem::Specification.new do |s|
  s.name        = "active_job_stats"
  s.summary     = "ActiveJobStats"
  s.version     = "0.0.4"
  s.authors     = ["Aliaksandr Yakubenka"]
  s.email       = "alexandr.yakubenko@startdatelabs.com"
  s.files       = ["lib/active_job_stats.rb"]
  s.license       = "MIT"
  s.add_dependency "activesupport"
  s.add_runtime_dependency "redis_connection"
end
