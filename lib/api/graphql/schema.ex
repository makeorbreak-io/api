defmodule Api.GraphQL.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias Api.GraphQL.Resolvers

  alias Api.Teams

  import_types Api.GraphQL.Types

  import_types Api.GraphQL.Queries.AICompetition
  import_types Api.GraphQL.Queries.AdminResources
  import_types Api.GraphQL.Queries.Competitions
  import_types Api.GraphQL.Queries.Flybys
  import_types Api.GraphQL.Queries.Integrations
  import_types Api.GraphQL.Queries.Suffrages
  import_types Api.GraphQL.Queries.Teams
  import_types Api.GraphQL.Queries.Workshops

  import_types Api.GraphQL.Mutations.AICompetition
  import_types Api.GraphQL.Mutations.Competitions
  import_types Api.GraphQL.Mutations.Emails
  import_types Api.GraphQL.Mutations.Flybys
  import_types Api.GraphQL.Mutations.Session
  import_types Api.GraphQL.Mutations.Suffrages
  import_types Api.GraphQL.Mutations.Teams
  import_types Api.GraphQL.Mutations.Users
  import_types Api.GraphQL.Mutations.Workshops

  query do
    import_fields :admin_resources
    import_fields :ai_competition_queries
    import_fields :competitions_queries
    import_fields :flybys_queries
    import_fields :integrations_queries
    import_fields :suffrages_queries
    import_fields :teams_queries
    import_fields :workshops_queries

    field :me, :user, resolve: &Resolvers.me/2
  end

  mutation do
    import_fields :ai_competition_mutations
    import_fields :competitions_mutations
    import_fields :emails_mutations
    import_fields :flybys_mutations
    import_fields :session_mutations
    import_fields :suffrages_mutations
    import_fields :teams_mutations
    import_fields :users_mutations
    import_fields :workshops_mutations
  end
end
