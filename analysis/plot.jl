function accuracy(df, N_blocks)
    IDs = unique(df[!, :subject_id])
    ACC = Matrix{Float64}(undef, length(IDs), N_blocks + 1)

    for (i, ID) in enumerate(IDs)
        responses = df[df.subject_id .== ID, :correct]
        resp_training = responses[1:N_training_trials]
        ACC[i, 1] = sum(resp_training) / length(resp_training)

        resp_test = responses[(N_training_trials + 1):end]
        sz_block = Int(ceil(length(resp_test) / N_blocks))
        responses_block = chunk(resp_test, sz_block)
        for (j, resp) in enumerate(responses_block)
            ACC[i, j+1] = sum(resp) / length(resp)
        end
    end

    return ACC
end

function difficulty(df, N_blocks)
    IDs = unique(df[!, :subject_id])
    D = Matrix{Float64}(undef, length(IDs), N_blocks + 1)

    for (i, ID) in enumerate(IDs)
        diff = df[df.subject_id .== ID, :difficulty]
        diff_training = diff[1:N_training_trials]
        D[i, 1] = mean(diff_training)

        diff_test = diff[(N_training_trials + 1):end]
        sz_block = Int(ceil(length(diff_test) / N_blocks))
        diff_block = chunk(diff_test, sz_block)
        for (j, d) in enumerate(diff_block)
            D[i, j+1] = mean(d)
        end
    end

    return D
end

function response_time(df, N_blocks)
    IDs = unique(df[!, :subject_id])
    RT = Matrix{Float64}(undef, length(IDs), N_blocks + 1)

    for (i, ID) in enumerate(IDs)
        rt_training = df[(df.subject_id .== ID) .& (df.phase .== "train"), :rt]
        RT[i, 1] = mean(rt_training)

        rt_test = df[(df.subject_id .== ID) .& (df.phase .== "test"), :rt]

        sz_block = Int(ceil(length(rt_test) / N_blocks))
        rt_block = chunk(rt_test, sz_block)
        for (j, r) in enumerate(rt_block)
            RT[i, j+1] = mean(r)
        end
    end

    return RT
end

function ITI_response(df, N_blocks)
    IDs = unique(df[!, :subject_id])
    RT = Matrix{Float64}(undef, length(IDs), N_blocks + 1)

    for (i, ID) in enumerate(IDs)
        rt_training = df[(df.subject_id .== ID) .& (df.phase .== "train"), :rt_iti]
        RT[i, 1] = mean(rt_training)

        rt_test = df[(df.subject_id .== ID) .& (df.phase .== "test"), :rt_iti]

        sz_block = Int(ceil(length(rt_test) / N_blocks))
        rt_block = chunk(rt_test, sz_block)
        for (j, r) in enumerate(rt_block)
            RT[i, j+1] = mean(r)
        end
    end

    return RT
end

function number_of_block_trials(df, N_blocks)
    IDs = unique(df[!, :subject_id])
    D = Matrix{Float64}(undef, length(IDs), N_blocks + 1)

    for (i, ID) in enumerate(IDs)
        diff = df[df.subject_id .== ID, :response]
        D[i, 1] = N_training_trials

        diff_test = diff[(N_training_trials + 1):end]
        sz_block = Int(ceil(length(diff_test) / N_blocks))
        diff_block = chunk(diff_test, sz_block)
        for (j, d) in enumerate(diff_block)
            D[i, j+1] = length(d)
        end
    end

    return D
end

function plot_diff_accuracy(df, N_blocks; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    
    ACC = accuracy(df, N_blocks)
    D = diff(ACC; dims=2)

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "Trial block",
        ylabel = "Difference in accuracy"
    )

    xs = 1:(N_blocks-1)

    for i in eachindex(IDs)
        d = D[i, :]
        lines!(ax, xs, d, color=(colormap[mod(i, length(colormap))+1], 0.2))
        scatter!(ax, xs, d, color=(colormap[mod(i, length(colormap))+1], 0.2))
    end

    for (i, acc_block) in enumerate(eachcol(D))
        errorbars!(ax, fill(i, length(acc_block)), mean(acc_block), std(acc_block), color=:black)
        scatter!(ax, [i], [mean(acc_block)], color=:black)
    end
    hlines!(ax, [0.0], linestyle = :dash, linewidth = 1.5, color=:grey)

    if save_plot
		save(string("./figures/diff_acc_", name, ".png"), f, pt_per_unit=1)
	end

    f
end

function plot_accuracy(df, N_blocks; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    
    ACC = accuracy(df, N_blocks)
    
    xs = 1:(N_blocks+1)

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "Trial block",
        ylabel = "Accuracy",
        xticks = (xs, vcat("Train", string.(1:N_blocks)))
    )

    for i in eachindex(IDs)
        acc = ACC[i, :]
        lines!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
        scatter!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
    end

    for (i, acc_block) in enumerate(eachcol(ACC))
        #errorbars!(ax, fill(i, length(acc_block)), mean(acc_block), std(acc_block), color=:black)
        scatter!(ax, [i], [mean(acc_block)], color=:black)
    end
    hlines!(ax, [0.5], linestyle = :dash, linewidth = 2, color=:grey)
    hlines!(ax, [0.75], linestyle = :dash, linewidth = 2, color=:black)

    if save_plot
		save(string("./figures/acc_", name, ".png"), f, pt_per_unit=1)
	end

    f
end

function plot_difficulty(df, N_blocks; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    
    D = difficulty(df, N_blocks)
    
    xs = 1:(N_blocks+1)

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "Trial block",
        ylabel = "Average difficulty",
        xticks = (xs, vcat("Train", string.(1:N_blocks))),
        yticks = 1:5
    )

    for i in eachindex(IDs)
        acc = D[i, :]
        lines!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
        scatter!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
    end

    for (i, diff_block) in enumerate(eachcol(D))
        #errorbars!(ax, fill(i, length(acc_block)), mean(acc_block), std(acc_block), color=:black)
        scatter!(ax, [i], [mean(diff_block)], color=:black)
    end

    if save_plot
		save(string("./figures/diff_", name, ".png"), f, pt_per_unit=1)
	end

    f
end

function plot_rt(df, N_blocks; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    
    RT = response_time(df, N_blocks)
    RT ./= 1000

    xs = 1:(N_blocks+1)

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "Trial block",
        ylabel = "Average RT [sec]",
        xticks = (xs, vcat("Train", string.(1:N_blocks)))
    )
    ylims!(ax, 0, 5)

    for i in eachindex(IDs)
        acc = RT[i, :]
        lines!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
        scatter!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
    end

    for (i, rt_block) in enumerate(eachcol(RT))
        scatter!(ax, [i], [mean(rt_block)], color=:black)
    end

    if save_plot
		save(string("./figures/rt_", name, ".png"), f, pt_per_unit=1)
	end

    f
end


function ecdf_rt(df; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "RT [sec]",
        ylabel = "ECDF",
        #xticks = (xs, vcat("Train", string.(1:N_blocks)))
    )

    for (i, id) in enumerate(IDs)
        rt = df[df.subject_id .== id, :rt] ./ 1000
        ecdfplot!(ax, rt, color=(colormap[mod(i, length(colormap))+1], 0.7))
    end

    if save_plot
		save(string("./figures/ecdf_rt_", name, ".png"), f, pt_per_unit=1)
	end

    f
end

function plot_iti(df, N_blocks; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    
    RT = ITI_response(df, N_blocks)
    RT ./= 1000

    xs = 1:(N_blocks+1)

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "Trial block",
        ylabel = "Average ITI response [sec]",
        xticks = (xs, vcat("Train", string.(1:N_blocks)))
    )
    ylims!(ax, 0, 8)

    for i in eachindex(IDs)
        acc = RT[i, :]
        lines!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
        scatter!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
    end

    for (i, rt_block) in enumerate(eachcol(RT))
        #errorbars!(ax, fill(i, length(acc_block)), mean(acc_block), std(acc_block), color=:black)
        scatter!(ax, [i], [mean(rt_block)], color=:black)
    end

    if save_plot
		save(string("./figures/rt_iti_", name, ".png"), f, pt_per_unit=1)
	end

    f
end

function plot_block_trials(df, N_blocks; name, save_plot=false)
    colormap = ColorSchemes.tab20.colors
    IDs = unique(df[!, :subject_id])    
    N = number_of_block_trials(df, N_blocks)

    xs = 1:(N_blocks+1)

    f = Figure()
    ax = Axis(
        f[1, 1], 
        xlabel = "Trial block",
        ylabel = "Number of block trials",
        xticks = (xs, vcat("Train", string.(1:N_blocks)))
    )
    ylims!(ax, 0, 25)

    for i in eachindex(IDs)
        acc = N[i, :]
        lines!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
        scatter!(ax, xs, acc, color=(colormap[mod(i, length(colormap))+1], 0.4))
    end

    for (i, N_block) in enumerate(eachcol(N))
        #errorbars!(ax, fill(i, length(acc_block)), mean(acc_block), std(acc_block), color=:black)
        scatter!(ax, [i], [mean(N_block)], color=:black)
    end

    if save_plot
		save(string("./figures/N_block_trials_", name, ".png"), f, pt_per_unit=1)
	end

    f
end
