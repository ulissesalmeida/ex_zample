children = [
  {Task.Supervisor, name: ExZample.TestTaskSupervisor}
]

Supervisor.start_link(children, strategy: :one_for_one)

ExUnit.start(exclude: [:skip])
