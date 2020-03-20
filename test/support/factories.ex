defmodule ExZample.User do
  @moduledoc false
  defstruct ~w(id first_name last_name age email)a
end

defmodule ExZample.Book do
  @moduledoc false
  defstruct title: "The Book's Title", code: "1321"
end

defmodule ExZample.Factories.User do
  @moduledoc false
  @behaviour ExZample

  @impl true
  def example do
    %ExZample.User{
      id: 1,
      first_name: "First Name",
      last_name: "Last Name",
      age: 21,
      email: "test@test.test"
    }
  end
end

defmodule ExZample.Factories.UserOnlyFullControl do
  @moduledoc false
  @behaviour ExZample

  @impl true
  def example(attrs) do
    %ExZample.User{
      id: Map.get(attrs, :id, 1) * 2,
      first_name: "full-control:" <> Map.get(attrs, :first_name, "first_name"),
      last_name: "full-control:" <> Map.get(attrs, :last_name, "last_name"),
      age: Map.get(attrs, :age, 1) * 3,
      email: "full-control:" <> Map.get(attrs, :last_name, "email")
    }
  end
end

defmodule ExZample.Factories.UserFullControlAndExample do
  @moduledoc false
  @behaviour ExZample

  @impl true
  def example do
    %ExZample.User{
      id: 777,
      first_name: "Example Full: First Name",
      last_name: "Example Full: Last Name",
      age: 25,
      email: "Example Full: test@test.test"
    }
  end

  @impl true
  def example(attrs) do
    %ExZample.User{
      id: Map.get(attrs, :id, 1) * 2,
      first_name: "full-control:" <> Map.get(attrs, :first_name, "first_name"),
      last_name: "full-control:" <> Map.get(attrs, :last_name, "last_name"),
      age: Map.get(attrs, :age, 1) * 3,
      email: "full-control:" <> Map.get(attrs, :email, "email")
    }
  end
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
