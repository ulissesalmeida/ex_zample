children = [
  {Task.Supervisor, name: ExZample.TestTaskSupervisor},
  ExZample.Repo
]

Supervisor.start_link(children, strategy: :one_for_one)

Ecto.Adapters.SQL.Sandbox.mode(ExZample.Repo, :manual)

ExUnit.start(exclude: [:skip])
