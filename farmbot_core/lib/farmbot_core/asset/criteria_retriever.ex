defmodule FarmbotCore.Asset.CriteriaRetriever do
  alias FarmbotCore.Asset.PointGroup
  @moduledoc """
      __      _ The PointGroup asset declares a list
    o'')}____// of criteria to query points. This
     `_/      ) module then converts that criteria to
     (_(_/-(_/  a list of real points that match the
                criteria of a point group.
     Example: You have a PointGroup with a criteria
              of `points WHERE x > 10`.
              Passing that PointGroup to this module
              will return an array of `Point` assets
              with an x property that is greater than
              10.
    """

    @numberic_fields ["radius", "x", "y", "z"]
    @string_fields ["name", "openfarm_slug", "plant_stage", "pointer_type"]

  def run(%PointGroup{} = _pg) do
    # Handle AND criteria
    # Handle point_id criteria
    # Handle meta.* criteria
  end

  def flatten(%PointGroup{} = pg) do
     {pg, []}
      |> handle_number_eq_fields()
      |> handle_number_gt_fields()
      |> handle_number_lt_fields()
      |> handle_string_eq_fields()
      |> handle_day_field()
  end

  defp handle_number_eq_fields({%PointGroup{} = pg, accum}) do
    {pg, accum ++ filter_it(pg, "number_eq", @numberic_fields, "IN")}
  end

  defp handle_number_gt_fields({%PointGroup{} = pg, accum}) do
    {pg, accum ++ filter_it(pg, "number_gt", @numberic_fields, ">")}
  end

  defp handle_number_lt_fields({%PointGroup{} = pg, accum}) do
    {pg, accum ++ filter_it(pg, "number_lt", @numberic_fields, "<")}
  end

  defp handle_string_eq_fields({%PointGroup{} = pg, accum}) do
    {pg, accum ++ filter_it(pg, "string_eq", @string_fields, "IN")}
  end

  defp handle_day_field({%PointGroup{} = pg, accum}) do
    op = pg.criteria["day"]["op"] || "<"
    days = pg.criteria["day"]["days"] || 0

    query = ["created_at #{op} ?", Timex.shift(Timex.now(), days: days)]

    { pg, accum ++ [ query ] }
  end

  defp filter_it(pg, criteria_kind, criteria_fields, op) do
    criteria_fields
      |> Enum.map(fn field ->
        {field, pg.criteria[criteria_kind][field]}
      end)
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.map(fn {k, v} -> ["#{k} #{op} ?", v] end)
  end
end