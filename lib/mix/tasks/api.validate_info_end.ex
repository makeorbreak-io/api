defmodule Mix.Tasks.Api.ValidateInfoEnd do
    use Mix.Task

    @shortdoc "Validates an info_end.json locally"

    @moduledoc """
      You can get an info_end.json on your User Dashboard after the voting ends.
    """

  alias Api.Suffrages

  def run(file_path) do
    file = if file_path == "-", do: :stdio, else: File.open!(file_path)
    doc = Poison.decode!(IO.read(file, :all))

    expected_podiums = doc["podiums"]
    votes_in_categories = doc["votes"]

    if Map.keys(expected_podiums) != Map.keys(votes_in_categories) do
      raise "Invalid file. podiums and votes have different categories!"
    end

    valid_teams =
      doc["teams"]
      |> Map.to_list
      |> Enum.reject(&(elem(&1, 1)["disqualified"]))

    valid_team_ids =
      valid_teams
      |> Enum.map(&(elem(&1, 0)))
      |> Enum.sort

    widest_team_id =
      valid_team_ids
      |> Enum.map(&String.length/1)
      |> Enum.sort
      |> List.last

    tie_breakers =
      valid_teams
      |> Map.new(fn {team_slug, attrs} ->
        {
          team_slug,
          attrs["tie_breaker"],
        }
      end)

    differences =
      Enum.map(votes_in_categories, fn {category, votes} ->
        expected_podium = expected_podiums[category]

        calculated_podium = Suffrages.calculate_podium(
          Suffrages.clean_votes_into_ballots(votes, valid_team_ids),
          valid_team_ids,
          tie_breakers
        )

        if expected_podium != calculated_podium do
          {category, expected_podium, calculated_podium}
        else
          nil
        end
      end)
      |> Enum.reject(&(&1 == nil))

    if Enum.count(differences) == 0 do
      Mix.shell.info "It looks valid! Calculated the voting locally and came to the same results."
      Mix.shell.info ""
      Mix.shell.info "Here's some debug info for the voting."

      Enum.map(votes_in_categories, fn {category, votes} ->
        separator = String.replace(category, ~r/./, "=")
        Mix.shell.info ""
        Mix.shell.info separator
        Mix.shell.info category
        Mix.shell.info separator

        preferences =
          Suffrages.clean_votes_into_ballots(votes, valid_team_ids)
          |> Enum.flat_map(&Markus.ballot_to_pairs(&1, valid_team_ids))
          |> Markus.pairs_to_preferences(valid_team_ids)

        widened_scores =
          preferences
          |> Markus.widen_paths(valid_team_ids)

        scores =
          widened_scores
          |> Markus.normalize_margins(valid_team_ids)

        sorted =
          scores
          |> Markus.sort_candidates_with_tie_breakers(valid_team_ids, tie_breakers)

        Mix.shell.info ""
        Mix.shell.info "Preference table"
        Mix.shell.info String.pad_leading("", widest_team_id, "-")
        preferences
        |> format_graph(sorted, widest_team_id)
        |> Mix.shell.info

        Mix.shell.info ""
        Mix.shell.info "Transitive preference table"
        Mix.shell.info String.pad_leading("", widest_team_id, "-")
        widened_scores
        |> format_graph(sorted, widest_team_id)
        |> Mix.shell.info

        Mix.shell.info ""
        Mix.shell.info "Beat table"
        Mix.shell.info String.pad_leading("", widest_team_id, "-")
        scores
        |> format_graph(
          sorted,
          widest_team_id,
           fn _ -> "  W" end
        )
        |> Mix.shell.info

        Mix.shell.info ""
        scores
        |> Markus.schwartz_set(valid_team_ids)
        |> _print_inspect(label: "Schwartz set")

        Mix.shell.info ""
        scores
        |> Markus.rank_candidates(valid_team_ids)
        |> _print_inspect(label: "Ranks")

        Mix.shell.info ""
        tie_breakers
        |> _print_inspect(label: "Tie breakers (lower wins)")

        Mix.shell.info ""
        sorted
        |> _print_inspect(label: "Final order")
      end)
    else
      Mix.shell.error "Things look funny."
      Enum.each(differences, fn {category, expected, calculated} ->
          Mix.shell.info Enum.join([
            "",
            "Podium for #{category} differs.",
            "Expected podium: #{inspect(expected)}",
            "Calculated podium: #{inspect(calculated)}",
          ], "\n")
      end)
    end
  end

  defp format_graph(scores, team_ids, widest_team_id, printer \\ nil) do
    printer = printer || fn n -> String.pad_leading(to_string(n), 3) end

    # Thanks, credo.
    internal_printer = fn scores, a, b ->
      s = scores[[a, b]]
      s_rev = scores[[b, a]]
      cond do
        a == b -> "  ."
        s == 0 and s_rev == 0 -> "  T"
        s == 0 -> "   "
        true -> printer.(s)
      end
    end

    Enum.map(team_ids, fn a ->
      ["#{String.pad_leading(a, widest_team_id)} "] ++ Enum.map(team_ids, fn b ->
        internal_printer.(scores, a, b)
      end)
      |> Enum.join("")
    end)
    |> Enum.join("\n")
  end

  defp _print_inspect(value, opts) do
    prefix = case Keyword.fetch(opts, :label) do
      {:ok, v} -> "#{v}: "
      :error -> ""
    end
    Mix.shell.info "#{prefix}#{inspect(value)}"
  end
end
