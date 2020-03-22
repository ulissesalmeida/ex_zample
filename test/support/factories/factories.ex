defmodule ExZample.User do
  @moduledoc false
  defstruct ~w(id first_name last_name age email)a
end

defmodule ExZample.Book do
  @moduledoc false
  defstruct title: "The Book's Title", code: "1321"
end

defmodule ExZample.UserWithDefaults do
  @moduledoc false
  defstruct first_name: "A name", last_name: "Last Name"
end

defmodule ExZample.UserWithDefaultsAndExample do
  @moduledoc false
  defstruct first_name: "Default name", last_name: "Default Last Name"

  @behaviour ExZample

  @impl true
  def example do
    %__MODULE__{
      first_name: "Example First Name",
      last_name: "Example Last Name"
    }
  end
end

defmodule ExZample.Factories do
  @moduledoc false

  use ExZample.DSL

  alias ExZample.User

  factory :user do
    example do
      %User{
        id: 1,
        first_name: "First Name",
        last_name: "Last Name",
        age: 21,
        email: "test@test.test"
      }
    end
  end

  factory ex_zample: :user do
    example do
      %User{
        id: 1,
        first_name: "Scoped: First Name",
        last_name: "Scoped: Last Name",
        age: 21,
        email: "Scoped: test@test.test"
      }
    end
  end

  factory :user_with_full_control do
    import Map, only: [get: 3]

    example(attrs) do
      %User{
        id: get(attrs, :id, 1) * 2,
        first_name: attrs |> get(:first_name, "first_name") |> prefix(),
        last_name: attrs |> get(:last_name, "last_name") |> prefix(),
        age: get(attrs, :age, 1) * 3,
        email: attrs |> get(:email, "email") |> prefix()
      }
    end

    defp prefix(string), do: "full-control:#{string}"
  end

  factory :user_with_full_control_and_example do
    import Map, only: [get: 3]

    example do
      %User{
        id: 777,
        first_name: "Example Full: First Name",
        last_name: "Example Full: Last Name",
        age: 25,
        email: "Example Full: test@test.test"
      }
    end

    example(attrs) do
      %User{
        id: get(attrs, :id, 1) * 2,
        first_name: attrs |> get(:first_name, "first_name") |> prefix(),
        last_name: attrs |> get(:last_name, "last_name") |> prefix(),
        age: get(attrs, :age, 1) * 3,
        email: attrs |> get(:email, "email") |> prefix()
      }
    end

    defp prefix(string), do: "full-control:#{string}"
  end
end

defmodule ExZample.ScopedFactories do
  @moduledoc false

  use ExZample.DSL, scope: :scoped

  factory :user do
    example do
      %ExZample.User{
        id: 1,
        first_name: "Global scoped: First Name",
        last_name: "Last Name",
        age: 21,
        email: "test@test.test"
      }
    end
  end

  factory overridden_scope: :user do
    example do
      %ExZample.User{
        id: 1,
        first_name: "Overriden Global Scope: First Name",
        last_name: "Last Name",
        age: 21,
        email: "test@test.test"
      }
    end
  end
end
