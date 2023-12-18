using CSV
using DataFrames
using CairoMakie
using ColorSchemes
using Statistics
using XLSX

include("plot.jl")

chunk(arr, n) = [arr[i:min(i + n - 1, end)] for i in 1:n:length(arr)]

omissions(df) = count(df[!, :response] .== "null")

function read_data(files, cols; filter_omissions=true)
    df = DataFrame()
    for f in files
        df_subj = CSV.read(f, DataFrame)
        if all(ismissing.(df_subj.subject_id))
            df_subj.subject_id .= rand(1001:9999)
        end
        df_subj.bonus[ismissing.(df_subj.bonus)] .= maximum(skipmissing(df_subj.bonus))
        df_subj.task[ismissing.(df_subj.task)] .= ""
        df_subj.response[ismissing.(df_subj.response)] .= ""
        df_subj.correct[ismissing.(df_subj.correct)] .= 0

        RT_ITI = collect(skipmissing(df_subj[df_subj.task .== "ITI", :rt]))
        RT_ITI[RT_ITI .== "null"] .= "5000"

        bonus = df_subj[findlast(x -> !ismissing(x), df_subj.bonus), :bonus]
        df_subj.bonus .= bonus

        df_subj = df_subj[df_subj.task .== "response", cols]
        
        df_subj.rt_iti .= RT_ITI[1:nrow(df_subj)]

        df_subj.subject_id = string.(df_subj.subject_id)

        if filter_omissions
            if (omissions(df_subj) / nrow(df_subj) <= 0.1)
                append!(df, df_subj)
            else
                @show (omissions(df_subj) / nrow(df_subj))
                @show nrow(df_subj)
            end
        else
            append!(df, df_subj)
        end
    end    

    return df
end

function subject_bonus(df)
    for ID in unique(df[!, :subject_id])
        println("$(ID) => $(maximum(df[df.subject_id .== ID, :bonus]))")
    end
end

function exemplar_incorrect_freq(df)
    idxs = @. !Bool(df.correct)
    df.stimulus[idxs]
end

function clean_RT!(df, θ_RT=200)
    filter!(df) do row
        RT = row.rt
        !ismissing(RT) && (RT != "null") && (RT != "") && (parse(Int, RT) > θ_RT)
    end

    df.rt .= parse.(Int, df.rt)
    df.rt_iti .= parse.(Int, df.rt_iti)

    return df
end

cols = [
    :subject_id,
    :time_elapsed,
    :stimulus,
    :task,
    :response,
    :correct,
    :correct_response,
    :rt,
    :bonus,
    :difficulty,
    :phase
]

global const N_training_trials = 10;

task = "SCM_noise"
dir = joinpath("./", task)

files = joinpath.(dir, readdir(dir))
filter!(f -> (last(split(f,'.')) == "csv") || (last(split(f,'.')) == "txt"), files)

df = read_data(files, cols; filter_omissions=true)

XLSX.writetable(string(dir, ".xlsx"), df)

clean_RT!(df, 0)

plot_accuracy(df, 8; save_plot=true, name=task)
plot_difficulty(df, 8; save_plot=true, name=task)
plot_rt(df, 8; save_plot=true, name=task)
plot_iti(df, 8; save_plot=true, name=task)
