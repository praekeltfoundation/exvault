# ExVault

[![Build Status](https://travis-ci.com/praekeltfoundation/exvault.svg?branch=master)](https://travis-ci.com/praekeltfoundation/exvault)
[![codecov](https://codecov.io/gh/praekeltfoundation/exvault/branch/master/graph/badge.svg)](https://codecov.io/gh/praekeltfoundation/exvault)
[![Inline docs](http://inch-ci.org/github/praekeltfoundation/exvault.svg?branch=master)](http://inch-ci.org/github/praekeltfoundation/exvault)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=praekeltfoundation/exvault)](https://dependabot.com)

Elixir client library for [HashiCorp Vault](https://www.vaultproject.io).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exvault` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exvault, "~> 0.1.0"},
  ]
end
```

Since the package isn't yet published, you can install from github:

```elixir
def deps do
  [
    {:exvault, git: "https://github.com/praekeltfoundation/exvault.git", sparse: "apps/exvault"},
  ]
end
```

## Basic Usage

Start by creating a client with an API URL and an authentication token:
```elixir
client = ExVault.new(address: "https://127.0.0.1:8200", token: "abcd-1234")
```

This client can then be used to make various API calls. Assuming a v1 key-value
secret backend is mounted at `/secret_kv_v1`:
```elixir
{:ok, _} = ExVault.write(client, "secret_kv_v1", "my_key", %{"hello" => "world"})

{:ok, resp} = ExVault.read(client, "secret_kv_v1", "my_key")
%{"hello" => "world"} = resp.logical.data

{:ok, _} = ExVault.delete(client, "secret_kv_v1", "my_key")

{:ok, resp} = ExVault.read(client, "secret_kv_v1", "my_key")
%ExVault.Response.Error{status: 404} = resp.logical.data
```
