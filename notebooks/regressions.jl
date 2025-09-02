using CSV, DataFrames, GLM, RegressionTables, Statistics, PrettyTables, Effects, LinearAlgebra, CairoMakie

function scale(df::DataFrame; cols::Vector{String} = names(df))
    result = copy(df)
    for col in cols
        result[!, col] = (df[!, col] .- mean(df[!, col])) ./ std(df[!, col])
    end
    return result
end

function scale(x::AbstractVector)
    return (x .- mean(x)) ./ std(x)
end

function scalem(x::AbstractVector)
    return (skipmissing(x) .- mean(skipmissing(x))) ./ std(skipmissing(x))
end

function model_to_df(model)
    return DataFrame(
        coef_name=GLM.coefnames(model),
        coef=GLM.coef(model),
        std_error=GLM.stderror(model),
        t=GLM.coeftable(model).cols[3],
        pr=GLM.coeftable(model).cols[4],
        lower=GLM.confint(model)[:,1],
        upper=GLM.confint(model)[:,2],
    )
end


"""
conditional_coef_link(m, x1::Symbol, x2::Symbol, cvals; level=0.95)

Compute the conditional coefficient of `x1` at values of `x2` = `cvals` on the *link scale*
for a GLM/LM `m` that includes the interaction `x1 & x2`.
Returns a DataFrame with estimate, SE, and confidence interval.

This method is developed with the aid of chatGPT.
"""
function conditional_coef_link(m, x1::Symbol, x2::Symbol, cvals; level=0.95)
    names = coefnames(m)
    # find indices for main and interaction terms
    ix1 = findfirst(==(String(x1)), names)
    iint = findfirst(n -> occursin(String(x1), n) && occursin(String(x2), n), names)
    isnothing(ix1)  && error("Couldn't find coefficient for $x1")
    isnothing(iint) && error("Couldn't find interaction coefficient for $x1:$x2")

    β   = coef(m)
    V   = vcov(m)
    α   = 1 - level
    z   = quantile(Normal(), 1 - α/2)

    result = DataFrame(x2_value = Float64[], estimate = Float64[],
                    se = Float64[], lower = Float64[], upper = Float64[])

    for c in cvals
        est = β[ix1] + c * β[iint]
        var = V[ix1, ix1] + c^2 * V[iint, iint] + 2c * V[ix1, iint]
        se  = sqrt(var)
        push!(result, (c, est, se, est - z*se, est + z*se))
    end
    result
end


output = "../output/regression";


bp=CSV.read("../output/budapest/20250428/indicators_with_ses.csv", DataFrame)
bp.mean_price = bp.walk15_mean_price
madrid=CSV.read("../output/madrid/20250415/indicators_with_ses.csv", DataFrame)
helsinki=CSV.read("../output/helsinki/20250428/indicators_with_ses.csv", DataFrame)

dropmissing!(helsinki, [:weighted_gini_walk, :weighted_gini_multi, :weighted_med_inc_walk, :weighted_med_inc_multi]);
dropmissing!(madrid, [:weighted_gini_walk, :weighted_gini_multi, :weighted_net_income_hh_walk, :weighted_net_income_hh_multi]);


cols=[
    "cultural_institutions_multimodal",
    "drugstores_multimodal",
    "groceries_multimodal",
    "healthcare_multimodal",
    "parks_multimodal",
    "religious_organizations_multimodal",
    "restaurants_multimodal",
    "schools_multimodal",
    "services_multimodal",
    "cultural_institutions_walk15",
    "drugstores_walk15",
    "groceries_walk15",
    "healthcare_walk15",
    "parks_walk15",
    "religious_organizations_walk15",
    "restaurants_walk15",
    "schools_walk15",
    "services_walk15",
];


is_there_amenity(x) = x > 0 ? 1 : 0
bp = bp[!, cols] .= is_there_amenity.(bp[!, cols])
madrid = madrid[!, cols] .= is_there_amenity.(madrid[!, cols])
helsinki = helsinki[!, cols] .= is_there_amenity.(helsinki[!, cols])


bp.walk_sum =
    bp.cultural_institutions_walk15 .+ bp.drugstores_walk15 .+ bp.groceries_walk15 .+
    bp.healthcare_walk15 .+ bp.parks_walk15 .+ bp.religious_organizations_walk15 .+
    bp.restaurants_walk15 .+ bp.schools_walk15 .+ bp.services_walk15
bp.multimod_sum =
    bp.cultural_institutions_multimodal .+ bp.drugstores_multimodal .+
    bp.groceries_multimodal .+ bp.healthcare_multimodal .+ bp.parks_multimodal .+
    bp.religious_organizations_multimodal .+ bp.restaurants_multimodal .+
    bp.schools_multimodal .+ bp.services_multimodal
helsinki.walk_sum =
    helsinki.cultural_institutions_walk15 .+ helsinki.drugstores_walk15 .+
    helsinki.groceries_walk15 .+ helsinki.healthcare_walk15 .+ helsinki.parks_walk15 .+
    helsinki.religious_organizations_walk15 .+ helsinki.restaurants_walk15 .+
    helsinki.schools_walk15 .+ helsinki.services_walk15
helsinki.multimod_sum =
    helsinki.cultural_institutions_multimodal .+ helsinki.drugstores_multimodal .+
    helsinki.groceries_multimodal .+ helsinki.healthcare_multimodal .+
    helsinki.parks_multimodal .+ helsinki.religious_organizations_multimodal .+
    helsinki.restaurants_multimodal .+ helsinki.schools_multimodal .+
    helsinki.services_multimodal
madrid.walk_sum =
    madrid.cultural_institutions_walk15 .+ madrid.drugstores_walk15 .+
    madrid.groceries_walk15 .+ madrid.healthcare_walk15 .+ madrid.parks_walk15 .+
    madrid.religious_organizations_walk15 .+ madrid.restaurants_walk15 .+
    madrid.schools_walk15 .+ madrid.services_walk15
madrid.multimod_sum =
    madrid.cultural_institutions_multimodal .+ madrid.drugstores_multimodal .+
    madrid.groceries_multimodal .+ madrid.healthcare_multimodal .+ madrid.parks_multimodal .+
    madrid.religious_organizations_multimodal .+ madrid.restaurants_multimodal .+
    madrid.schools_multimodal .+ madrid.services_multimodal


# # 2.0 Main regressions without interactions


bp.gini_diff_exp = bp.gini_multimodal .- bp.gini_walk15
bp.gini_diff_house = bp.gini_house_multimodal .- bp.gini_house_walk15

helsinki.gini_diff = helsinki.weighted_gini_multi .- helsinki.weighted_gini_walk
madrid.gini_diff = madrid.weighted_gini_multi .- madrid.weighted_gini_walk


bp.access_diff = bp.multimod_sum .- bp.walk_sum
madrid.access_diff = madrid.multimod_sum .- madrid.walk_sum
helsinki.access_diff = helsinki.multimod_sum .- helsinki.walk_sum



bp1_noint = lm(
    @formula(
        gini_diff_exp ~ gini_walk15 + area_difference + ellipticity + distance_betweenness
    ),
    bp,
)

bp2_noint = lm(
    @formula(
        gini_diff_house ~
        gini_walk15 + area_difference + ellipticity + distance_betweenness
    ),
    bp,
)

helsinki1_noint = lm(
    @formula(
        gini_diff ~
        weighted_gini_walk + area_difference + ellipticity + distance_betweenness
    ),
    helsinki,
)

madrid1_noint = lm(
    @formula(
        gini_diff ~
        weighted_gini_walk + area_difference + ellipticity + distance_betweenness
    ),
    madrid,
)

bp1a_noint = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    bp,
)

helsinki1a_noint = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    helsinki,
)

madrid1a_noint = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    madrid,
)

regtable(
    helsinki1a_noint,
    madrid1a_noint,
    bp1a_noint,
    helsinki1_noint,
    madrid1_noint,
    bp2_noint,
    bp1_noint;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff" => "Access", "gini_diff" => "Gini", "gini_diff_house" => "Residential Gini", "gini_diff_exp" => "Experienced Gini"),
    wrap_table = true,
    label = "tab:madrid_stats",
    file="$(output)/SI_Reg_1_noint.tex"
)
# label = "tab:madrid_stats", title = "Summary Statistics for Madrid", wrap_table = true
regtable(
    helsinki1a_noint,
    madrid1a_noint,
    bp1a_noint,
    helsinki1_noint,
    madrid1_noint,
    bp2_noint,
    bp1_noint;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff" => "Access", "gini_diff" => "Gini", "gini_diff_house" => "Residential Gini", "gini_diff_exp" => "Experienced Gini"),
    file="$(output)/SI_Reg_1_noint.txt"
)



# pretty_table(stdout, mad_sum, backend = Val(:latex); show_subheader=false, label = "tab:madrid_stats", title = "Summary Statistics for Madrid", wrap_table = true)


# bp_avg_price = CSV.read("../src/regression/budapest/stop_property_price.csv", DataFrame);
# bp = leftjoin(bp, bp_avg_price, on="stop_id");



bp1_noint_l = lm(@formula(
  gini_diff_exp ~ gini_walk15 + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.arpu_low_ratio_walk15 > median(bp.arpu_low_ratio_walk15), bp),
)

bp1_noint_h = lm(@formula(
  gini_diff_exp ~ gini_walk15 + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.arpu_low_ratio_walk15 < median(bp.arpu_low_ratio_walk15), bp),
)

bp2_noint_l = lm(@formula(
  gini_diff_house ~ gini_walk15 + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.mean_price < median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

bp2_noint_h = lm(@formula(
  gini_diff_house ~ gini_walk15 + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.mean_price > median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

helsinki1_noint_l = lm(@formula(
  gini_diff ~ weighted_gini_walk + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_med_inc_walk < median(helsinki.weighted_med_inc_walk), helsinki),
)

helsinki1_noint_h = lm(@formula(
  gini_diff ~ weighted_gini_walk + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_med_inc_walk > median(helsinki.weighted_med_inc_walk), helsinki),
)

madrid1_noint_l = lm(@formula(
  gini_diff ~ weighted_gini_walk + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_net_income_hh_walk < median(madrid.weighted_net_income_hh_walk), madrid),
)

madrid1_noint_h = lm(@formula(
  gini_diff ~ weighted_gini_walk + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_net_income_hh_walk > median(madrid.weighted_net_income_hh_walk), madrid),
)

bp1a_noint_l = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.mean_price < median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

bp1a_noint_h = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.mean_price > median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

helsinki1a_noint_l = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_med_inc_walk < median(helsinki.weighted_med_inc_walk), helsinki),
)

helsinki1a_noint_h = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_med_inc_walk > median(helsinki.weighted_med_inc_walk), helsinki),
)

madrid1a_noint_l = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_net_income_hh_walk < median(madrid.weighted_net_income_hh_walk), madrid),
)

madrid1a_noint_h = lm(
    @formula(access_diff ~ walk_sum + area_difference + ellipticity + distance_betweenness),
    filter(row -> row.weighted_net_income_hh_walk > median(madrid.weighted_net_income_hh_walk), madrid),
)

regtable(
    helsinki1a_noint_l,
    madrid1a_noint_l,
    bp1a_noint_l,
    helsinki1_noint_l,
    madrid1_noint_l,
    bp2_noint_l,
    bp1_noint_l;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff" => "Access", "gini_diff" => "Gini", "gini_diff_house" => "Residential Gini", "gini_diff_exp" => "Experienced Gini"),
    file="$(output)/SI_Reg_2_noint_low.tex"
)
regtable(
    helsinki1a_noint_l,
    madrid1a_noint_l,
    bp1a_noint_l,
    helsinki1_noint_l,
    madrid1_noint_l,
    bp2_noint_l,
    bp1_noint_l;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff" => "Access", "gini_diff" => "Gini", "gini_diff_house" => "Residential Gini", "gini_diff_exp" => "Experienced Gini"),
    file="$(output)/SI_Reg_2_noint_low.txt"
)


regtable(
    helsinki1a_noint_h,
    madrid1a_noint_h,
    bp1a_noint_h,
    helsinki1_noint_h,
    madrid1_noint_h,
    bp2_noint_h,
    bp1_noint_h;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff" => "Access", "gini_diff" => "Gini", "gini_diff_house" => "Residential Gini", "gini_diff_exp" => "Experienced Gini"),
    file="$(output)/SI_Reg_3_noint_high.tex"
)
regtable(
    helsinki1a_noint_h,
    madrid1a_noint_h,
    bp1a_noint_h,
    helsinki1_noint_h,
    madrid1_noint_h,
    bp2_noint_h,
    bp1_noint_h;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff" => "Access", "gini_diff" => "Gini", "gini_diff_house" => "Residential Gini", "gini_diff_exp" => "Experienced Gini"),
    file="$(output)/SI_Reg_3_noint_high.txt"
)


# plotting

model_names = ["helsinki1a_noint", "madrid1a_noint", "bp1a_noint",
                 "helsinki1_noint", "madrid1_noint", "bp2_noint", "bp1_noint",
                 "helsinki1a_noint_l", "madrid1a_noint_l", "bp1a_noint_l",
                 "helsinki1_noint_l", "madrid1_noint_l", "bp2_noint_l", "bp1_noint_l",
                 "helsinki1a_noint_h", "madrid1a_noint_h", "bp1a_noint_h",
                 "helsinki1_noint_h", "madrid1_noint_h", "bp2_noint_h", "bp1_noint_h"];


# # 4.2 Regressions with interactions into SI

bp1 = lm(
    @formula(gini_multimodal - gini_walk15 ~ gini_walk15 + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    bp,
)

bp2 = lm(
    @formula(gini_house_multimodal - gini_house_walk15 ~ gini_walk15 + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    bp,
)

helsinki1 = lm(
    @formula(weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    helsinki,
)

madrid1 = lm(
    @formula(weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    madrid,
)


# # 4.2 Access


bp1a = lm(
    @formula(multimod_sum - walk_sum ~ walk_sum + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    bp,
)

helsinki1a = lm(
    @formula(multimod_sum - walk_sum ~ walk_sum + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    helsinki,
)

madrid1a = lm(
    @formula(multimod_sum - walk_sum ~ walk_sum + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    madrid,
)

regtable(
    helsinki1a, madrid1a, bp1a,helsinki1, madrid1, bp2, bp1;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    file="$(output)/SI_Reg_4.tex"
)
regtable(
    helsinki1a, madrid1a, bp1a,helsinki1, madrid1, bp2, bp1;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    file="$(output)/SI_Reg_4.txt"
)


# # 4.3 Standardized regressions with interactions


to_scale = ["gini_diff", "area_difference", "ellipticity", "distance_betweenness", "access_diff", "walk_sum"];

for i in vcat(["gini_diff_exp"], to_scale[2:end], ["gini_walk15", "gini_diff_house"])
    bp[!, "$(i)_s"] = scale(bp[!, i])
end;
for i in vcat(to_scale, ["weighted_gini_walk"])
    madrid[!, "$(i)_s"] = scale(madrid[!, i])
    helsinki[!, "$(i)_s"] = scale(helsinki[!, i])
end;


helsinki[!, "weighted_gini_walk"]


scalem(helsinki[!, "weighted_gini_walk"])


bp1_s = lm(
    @formula(gini_diff_exp_s ~ gini_walk15_s + area_difference_s + ellipticity + distance_betweenness_s),
    bp,
)
# TODO: ellipticity is not scaled, but it seems not need to


bp2_s = lm(
    @formula(gini_diff_house_s ~ gini_walk15_s + area_difference_s + ellipticity + distance_betweenness_s),
    bp,
)


helsinki1_s = lm(
    @formula(gini_diff_s ~ weighted_gini_walk_s + area_difference_s + ellipticity + distance_betweenness_s),
    helsinki,
)

madrid1_s = lm(
    @formula(gini_diff_s ~ weighted_gini_walk_s + area_difference_s + ellipticity + distance_betweenness_s),
    madrid,
)

bp1a_s = lm(
    @formula(access_diff_s ~ walk_sum_s + area_difference_s + ellipticity + distance_betweenness_s),
    bp,
)

helsinki1a_s = lm(
    @formula(access_diff_s ~ walk_sum_s + area_difference_s + ellipticity + distance_betweenness_s),
    helsinki,
)

madrid1a_s = lm(
    @formula(access_diff_s ~ walk_sum_s + area_difference_s + ellipticity + distance_betweenness_s),
    madrid,
)


regtable(
    helsinki1a_s, madrid1a_s, bp1a_s, helsinki1_s, madrid1_s, bp2_s, bp1_s;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff_s" => "Access (standardized)", "gini_diff_s" => "Gini (standardized)", "gini_diff_house_s" => "Residential Gini (standardized)", "gini_diff_exp_s" => "Experienced Gini (standardized)"),
    file="$(output)/SI_Reg_5_s.tex"
)
regtable(
    helsinki1a_s, madrid1a_s, bp1a_s, helsinki1_s, madrid1_s, bp2_s, bp1_s;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest", "Budapest"],
    labels=Dict("access_diff_s" => "Access (standardized)", "gini_diff_s" => "Gini (standardized)", "gini_diff_house_s" => "Residential Gini (standardized)", "gini_diff_exp_s" => "Experienced Gini (standardized)"),
    file="$(output)/SI_Reg_5_s.txt"
)


# # 4.4 interplots


bp1i = lm(
    @formula(gini_multimodal - gini_walk15 ~ gini_walk15 + area_difference + (distance_betweenness * ellipticity)),
    bp,
)

bp2i = lm(
    @formula(gini_house_multimodal - gini_house_walk15 ~ gini_walk15 + area_difference + (distance_betweenness * ellipticity)),
    bp,
)

helsinki1i = lm(
    @formula(weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk + area_difference + (distance_betweenness * ellipticity)),
    helsinki,
)

madrid1i = lm(
    @formula(weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk + area_difference + (distance_betweenness * ellipticity)),
    madrid,
)

bp1ai = lm(
    @formula(multimod_sum - walk_sum ~ walk_sum + area_difference + (distance_betweenness * ellipticity)),
    bp,
)

helsinki1ai = lm(
    @formula(multimod_sum - walk_sum ~ walk_sum + area_difference + (distance_betweenness * ellipticity)),
    helsinki,
)

madrid1ai = lm(
    @formula(multimod_sum - walk_sum ~ walk_sum + area_difference + (distance_betweenness * ellipticity)),
    madrid,
)



cvals = quantile(bp.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(bp1i, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_bp1.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    # xlabel = "distance_betweenness",
    # ylabel = "Conditional effect of ellipticity",
    # title  = "Conditional Coefficient Plot"
    xlabel = L"$D_i$",
    ylabel = L"Coefficient of $E_i$ on $G_i$ by levels of $D_i$",
)
lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

# hlines!(ax, [0], color=:black, linestyle=:dash)  # zero line for reference
save("$(output)/main_interplot_bp1.png", fig)
fig



cvals = quantile(bp.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(bp2i, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_bp2.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

# hlines!(ax, [0], color=:black, linestyle=:dash)  # zero line for reference
save("$(output)/main_interplot_bp2.png", fig)
fig


cvals = quantile(helsinki.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(helsinki1i, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_helsinki1.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

save("$(output)/main_interplot_helsinki1.png", fig)
fig


cvals = quantile(madrid.distance_betweenness,0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(madrid1i, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_madrid1.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

save("$(output)/main_interplot_madrid1.png", fig)
fig


cvals = quantile(bp.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(bp1ai, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_bp1a.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

save("$(output)/main_interplot_bp1a.png", fig)
fig


cvals = quantile(helsinki.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(helsinki1ai, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_helsinki1a.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

save("$(output)/main_interplot_helsinki1a.png", fig)
fig


cvals = quantile(madrid.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(madrid1ai, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_madrid1a.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

save("$(output)/main_interplot_madrid1a.png", fig)
fig


cvals = quantile(madrid.distance_betweenness, 0:1/30:1)  # pick any values you like
res_link = conditional_coef_link(madrid1ai, :ellipticity, :distance_betweenness, cvals)
CSV.write("$(output)/main_interplot_madrid1a.csv", res_link);

fig = Figure()
ax = Axis(fig[1, 1],
    xlabel = "distance_betweenness",
    ylabel = "Conditional effect of ellipticity",
)

lines!(ax, res_link.x2_value, res_link.estimate, color=:blue)
band!(ax, res_link.x2_value, res_link.lower, res_link.upper, color=(:blue, 0.3))

save("$(output)/main_interplot_madrid1a.png", fig)
fig


# # 4.6 Consider socio-economic status of walking area - interactions


bp1_l = lm(@formula(
    gini_multimodal - gini_walk15 ~ gini_walk15 +( area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.arpu_low_ratio_walk15 > median(bp.arpu_low_ratio_walk15), bp),
)

bp1_h = lm(@formula(
    gini_multimodal - gini_walk15 ~ gini_walk15 +( area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.arpu_low_ratio_walk15 < median(bp.arpu_low_ratio_walk15), bp),
)

bp2_l = lm(@formula(
    gini_house_multimodal - gini_house_walk15 ~ gini_walk15 + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.mean_price < median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

bp2_h = lm(@formula(
    gini_house_multimodal - gini_house_walk15 ~ gini_walk15 + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.mean_price > median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

helsinki1_l = lm(@formula(
    weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_med_inc_walk < median(helsinki.weighted_med_inc_walk), helsinki),
)

helsinki1_h = lm(@formula(
    weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_med_inc_walk > median(helsinki.weighted_med_inc_walk), helsinki),
)

madrid1_l = lm(@formula(
    weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_net_income_hh_walk < median(madrid.weighted_net_income_hh_walk), madrid),
)

madrid1_h = lm(@formula(
    weighted_gini_multi - weighted_gini_walk ~ weighted_gini_walk +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_net_income_hh_walk > median(madrid.weighted_net_income_hh_walk), madrid),
)

bp1a_l = lm(@formula(
    multimod_sum - walk_sum ~ walk_sum + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.mean_price < median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

bp1a_h = lm(@formula(
    multimod_sum - walk_sum ~ walk_sum + (area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.mean_price > median(skipmissing(bp.mean_price)), dropmissing(bp, :mean_price)),
)

helsinki1a_l = lm(@formula(
    multimod_sum - walk_sum ~ walk_sum +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_med_inc_walk < median(helsinki.weighted_med_inc_walk), helsinki),
)

helsinki1a_h = lm(@formula(
    multimod_sum - walk_sum ~ walk_sum +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_med_inc_walk > median(helsinki.weighted_med_inc_walk), helsinki),
)

madrid1a_l = lm(@formula(
    multimod_sum - walk_sum ~ walk_sum +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_net_income_hh_walk < median(madrid.weighted_net_income_hh_walk), madrid),
)

madrid1a_h = lm(@formula(
    multimod_sum - walk_sum ~ walk_sum +(area_difference * ellipticity) + (distance_betweenness * ellipticity)),
    filter(row -> row.weighted_net_income_hh_walk > median(madrid.weighted_net_income_hh_walk), madrid),
)

regtable(
    helsinki1a_l, madrid1a_l, bp1a_l, helsinki1_l, madrid1_l, bp2_l, bp1_l,;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest (property price)", "Budapest (subscriber info)"],
    file="$(output)/SI_Reg_6_low.tex"
)
regtable(
    helsinki1a_l, madrid1a_l, bp1a_l, helsinki1_l, madrid1_l, bp2_l, bp1_l,;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest (property price)", "Budapest (subscriber info)"],
    file="$(output)/SI_Reg_6_low.txt"
)


regtable(
    helsinki1a_h, madrid1a_h, bp1a_h, helsinki1_h, madrid1_h, bp2_h, bp1_h;
    render = LatexTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest (property price)", "Budapest (subscriber info)"],
    file="$(output)/SI_Reg_7_high.tex"
)
regtable(
    helsinki1a_h, madrid1a_h, bp1a_h, helsinki1_h, madrid1_h, bp2_h, bp1_h;
    render = AsciiTable(),
    groups=["Helsinki", "Madrid", "Budapest", "Helsinki", "Madrid", "Budapest (property price)", "Budapest (subscriber info)"],
    file="$(output)/SI_Reg_7_high.txt"
)


# # 4.7 Correlation plots


vars_bp = ["access_diff","gini_diff_exp", "gini_diff_house", "walk_sum", "gini_walk15", "area_difference", "ellipticity", "distance_betweenness"];
vars_he = ["access_diff","gini_diff", "walk_sum","weighted_gini_walk", "area_difference", "ellipticity", "distance_betweenness"];
vars_ma = ["access_diff","gini_diff", "walk_sum","weighted_gini_walk", "area_difference", "ellipticity", "distance_betweenness"];

corr_mx_bp = cor(Matrix(bp[:,vars_bp]))

CSV.write("$(output)/bud_for_corrplot.csv", bp[:, vars_bp]);
CSV.write("$(output)/hel_for_corrplot.csv", helsinki[:, vars_he]);
CSV.write("$(output)/mad_for_corrplot.csv", madrid[:, vars_ma]);


# # 4.8 Variable Statistics


# Subset and drop missing data
bp_sub = dropmissing(bp[:, vars_bp])
helsinki_sub = dropmissing(helsinki[:, vars_he])
madrid_sub = dropmissing(madrid[:, vars_ma])


bud_sum = describe(bp_sub, :min, :q25, :median, :mean, :q75, :max, :std)
CSV.write("$(output)/SI_summary_bp.csv", bud_sum);
hel_sum = describe(helsinki_sub, :min, :q25, :median, :mean, :q75, :max, :std)
CSV.write("$(output)/SI_summary_helsinki.csv", hel_sum);
mad_sum = describe(madrid_sub, :min, :q25, :median, :mean, :q75, :max, :std)
CSV.write("$(output)/SI_summary_madrid.csv", mad_sum);


open("$(output)/SI_summary_bp.tex", "w") do io
    pretty_table(io, bud_sum, backend = Val(:latex); show_subheader=false, label = "tab:budapest_stats", title = "Summary Statistics for Budapest", wrap_table = true)
end
open("$(output)/SI_summary_helsinki.tex", "w") do io
    pretty_table(io, hel_sum, backend = Val(:latex); show_subheader=false, label = "tab:helsinki_stats", title = "Summary Statistics for Helsinki", wrap_table = true)
end
open("$(output)/SI_summary_madrid.tex", "w") do io
    pretty_table(io, mad_sum, backend = Val(:latex); show_subheader=false, label = "tab:madrid_stats", title = "Summary Statistics for Madrid", wrap_table = true)
end

