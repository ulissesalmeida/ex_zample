defmodule ExZample.DSLTest do
  use ExUnit.Case, async: false

  alias ExZample.Factories.{
    ExZampleUserFactory,
    UserFactory,
    UserWithFullControlAndExampleFactory,
    UserWithFullControlFactory
  }

  alias ExZample.ScopedFactories.{
    OverriddenScopeUserFactory,
    ScopedUserFactory
  }

  alias ExZample.User

  import ExZample

  setup do
    :ok = Application.ensure_started(:ex_zample)

    on_exit(fn ->
      Application.stop(:ex_zample)
    end)
  end

  describe "factories generation" do
    test "generates simple factories" do
      assert %User{} = UserFactory.example()
    end

    test "generates scoped factories" do
      assert %User{} = ExZampleUserFactory.example()
    end

    test "generates factories with full control" do
      assert %User{} = UserWithFullControlFactory.example(%{})
    end

    test "generates factories with full control and example" do
      assert %User{} = UserWithFullControlAndExampleFactory.example()
      assert %User{} = UserWithFullControlAndExampleFactory.example(%{})
    end

    test "generates global scoped factories" do
      assert %User{} = ScopedUserFactory.example()
    end

    test "generates global scoped factories with overridden scope" do
      assert %User{} = OverriddenScopeUserFactory.example()
    end
  end

  describe "alias configuartion for factories" do
    setup :ex_zample

    test "generates for simple factories" do
      assert %User{first_name: "First Name"} = build(:user)
    end

    @tag ex_zample_scope: :ex_zample
    test "generates for scoped factories" do
      assert %User{first_name: "Scoped: First Name"} = build(:user)
    end

    test "generates for factories with full control" do
      assert %User{} = build(:user_with_full_control)
    end

    test "generates for factories with full control and example" do
      assert %User{} = build(:user_with_full_control_and_example)
      assert %User{} = build(:user_with_full_control_and_example, %{})
    end

    @tag ex_zample_scope: :scoped
    test "generates for global scoped factories" do
      assert %User{first_name: "Global scoped: First Name"} = build(:user)
    end

    @tag ex_zample_scope: :overridden_scope
    test "generates for global scoped factories with overridden scope" do
      assert %User{first_name: "Overriden Global Scope: First Name"} = build(:user)
    end
  end

  describe "sequences generation" do
    alias ExZample.{Factories, ScopedFactories}

    test "generates simple sequences" do
      assert 1 == Factories.user_id_sequence().(1)
    end

    test "generates scoped sequences" do
      assert "ex_zample_user_1" == Factories.ex_zample_user_id_sequence().(1)
    end

    test "generates global scoped sequences" do
      assert "scoped_user_1" == ScopedFactories.scoped_user_id_sequence().(1)
    end

    test "generates global scoped factories with overridden scope" do
      assert "overridden_scope_user_1" = ScopedFactories.overridden_scope_user_id_sequence().(1)
    end
  end

  describe "alias configuartion for sequences" do
    setup :ex_zample

    test "generates simple sequences" do
      assert 1 == sequence(:user_id)
    end

    test "files only with sequences are loaded" do
      assert 1 == sequence(:only_sequences_file)
    end

    @tag ex_zample_scope: :ex_zample
    test "generates scoped sequences" do
      assert "ex_zample_user_1" == sequence(:user_id)
    end

    @tag ex_zample_scope: :scoped
    test "generates global scoped sequences" do
      assert "scoped_user_1" == sequence(:user_id)
    end

    @tag ex_zample_scope: :overridden_scope
    test "generates global scoped factories with overridden scope" do
      assert "overridden_scope_user_1" = sequence(:user_id)
    end
  end
end
