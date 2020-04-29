defmodule Api.GraphQL.Schema do
  use Absinthe.Schema

  alias Api.GraphQL.Resolvers

  import_types Api.GraphQL.Types

  import_types Api.GraphQL.Queries.AICompetition
  import_types Api.GraphQL.Queries.AdminResources
  import_types Api.GraphQL.Queries.Editions
  import_types Api.GraphQL.Queries.Flybys
  import_types Api.GraphQL.Queries.Integrations
  import_types Api.GraphQL.Queries.Suffrages
  import_types Api.GraphQL.Queries.Teams
  import_types Api.GraphQL.Queries.Events

  import_types Api.GraphQL.Mutations.AICompetition
  import_types Api.GraphQL.Mutations.Editions
  import_types Api.GraphQL.Mutations.Emails
  import_types Api.GraphQL.Mutations.Flybys
  import_types Api.GraphQL.Mutations.Session
  import_types Api.GraphQL.Mutations.Suffrages
  import_types Api.GraphQL.Mutations.Teams
  import_types Api.GraphQL.Mutations.Users
  import_types Api.GraphQL.Mutations.Events

  query do
    import_fields :admin_resources
    import_fields :ai_competition_queries
    import_fields :editions_queries
    import_fields :flybys_queries
    import_fields :integrations_queries
    import_fields :suffrages_queries
    import_fields :teams_queries
    import_fields :events_queries

    field :me, :user, resolve: &Resolvers.me/2
  end

  mutation do
    import_fields :ai_competition_mutations
    import_fields :editions_mutations
    import_fields :emails_mutations
    import_fields :flybys_mutations
    import_fields :session_mutations
    import_fields :suffrages_mutations
    import_fields :teams_mutations
    import_fields :users_mutations
    import_fields :events_mutations
  end
end
