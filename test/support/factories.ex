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
