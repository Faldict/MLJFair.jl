Base.zero(::Type{Union{Int64, VariableRef, GenericAffExpr{Float64,VariableRef}}}) = 0

# Helper function to modify the fairness tensor according to the values for sp2n, on2p, etc
# vals is a 2D array of the form [[sp2n, sn2p], [op2n, on2p]]
function _fairTensorLinProg!(ft::FairTensor, vals)
	mat = deepcopy(ft.mat)
	ft.mat = zeros(Union{VariableRef, Int, GenericAffExpr{Float64,VariableRef}}, size(mat)...)
	for i in 1:length(ft.labels)
		p2n, n2p = vals[i, :] #These vals are VariableRef from library JuMP
		p2p, n2n = 1-p2n, 1-n2p
		a = zeros(Union{VariableRef, Int, GenericAffExpr{Float64,VariableRef}}, 2, 2) # The numbers for modified fairness tensor values for a group
		a[1, 1] = mat[i, 1, 1]*p2p + mat[i, 2, 2]*n2p
		a[1, 2] = mat[i, 1, 2]*p2p + mat[i, 2, 1]*n2p
		a[2, 1] = mat[i, 2, 1]*n2n + mat[i, 1, 1]*p2n
		a[2, 2] = mat[i, 2, 2]*n2n + mat[i, 1, 2]*p2n
		ft.mat[i, :, :] = a
	end
end

"""
    LinProgWrapper

It is a postprocessing algorithm that uses JuMP and Ipopt library to minimise error and satisfy the equality of specified specified measures for all groups at the same time.
Automatic differentiation and gradient based optimisation is used to find probabilities with which the predictions are changed for each group.
"""
mutable struct LinProgWrapper <: DeterministicComposite
	grp::Symbol
	classifier::MLJBase.Model
	measure::Measure
end

"""
    LinProgWrapper(classifier; grp=:class, measure)

Instantiates LinProgWrapper which wraps the classifier and containts the measure to optimised and the sensitive attribute(grp)
"""
function LinProgWrapper(classifier::MLJBase.Model; grp::Symbol=:class, measure::Measure)
	return LinProgWrapper(grp, classifier, measure)
end

function MMI.fit(model::LinProgWrapper, verbosity::Int, X, y)
	grps = X[:, model.grp]
	n = length(levels(grps)) # Number of different values for sensitive attribute

	# As LinProgWrapper is a postprocessing algorithm, the model needs to be fitted first
	mch = machine(model.classifier, X, y)
	fit!(mch)
	ŷ = MMI.predict(mch, X)

	if typeof(ŷ[1]) <: MLJBase.UnivariateFinite
		ŷ = MLJBase.mode.(ŷ)
	end

	ŷ = convert(Array, ŷ) # Incase ŷ is categorical array, convert to normal array to support various operations
	y = convert(Array, y)

	# Finding the probabilities of changing predictions is a Linear Programming Problem
	# JuMP and Ipopt Optimizer are used to for this Linear Programming Problem
	m = JuMP.Model(Ipopt.Optimizer)

	@variable(m, 0<= p2p[1:n] <=1)
	@variable(m, 0<= p2n[1:n] <=1)
	@variable(m, 0<= n2p[1:n] <=1)
	@variable(m, 0<= n2n[1:n] <=1)

	@constraint(m, [i=1:n], p2p[i] == 1 - p2n[i])
	@constraint(m, [i=1:n], n2p[i] == 1 - n2n[i])

	ft = fair_tensor(categorical(ŷ), categorical(y), categorical(grps))

	vals = zeros(Union{VariableRef, Int, GenericAffExpr{Float64,VariableRef}}, n, 2)
	vals[: , 1] = p2n
	vals[: , 2] = n2p

	_fairTensorLinProg!(ft, vals)

	mat = reshape(ft.mat, (4n))
	@variable(m, aux[1:4n])
	@constraint(m,[i=1:4n], mat[i]==aux[i])

	register(m, :fpr, 4n, (x...)->fpr(MLJFair.FairTensor{n}(reshape(collect(x), (n, 2, 2)), ft.labels)), autodiff=true)
	register(m, :fnr, 4n, (x...)->fnr(MLJFair.FairTensor{n}(reshape(collect(x), (n, 2, 2)), ft.labels)), autodiff=true)
	@NLobjective(m, Min, fpr(aux...) + fnr(aux...))

	measure = model.measure
	register(m, :ms, 9, (i, x...)->measure(MLJFair.FairTensor{2}(reshape(collect(x), (n, 2, 2)), ft.labels), grp=levels(grps)[1]), autodiff=true)

	@NLexpression(m, ms[i=1:n], ms(i, aux...))

	@NLconstraint(m, [i=2:n], ms[1]==ms[i])

	optimize!(m)

	fitresult = [[JuMP.value.(p2n), JuMP.value.(n2p)], mch.fitresult]

	return fitresult, nothing, nothing
end

# Corresponds to eq_odds function which uses mix_rates to modify results
function MMI.predict(model::LinProgWrapper, fitresult, Xnew)

	(p2n, n2p), classifier_fitresult = fitresult

	ŷ = MMI.predict(model.classifier, classifier_fitresult, Xnew)

	if typeof(ŷ[1]) <: MLJBase.UnivariateFinite
		ŷ = MLJBase.mode.(ŷ)
	end

	ŷ = convert(Array, ŷ) # Need to convert to normal array as categorical array doesn't support sub
	grps = Xnew[:, model.grp]

	n = length(levels(grps)) # Number of different values for sensitive attribute

	for i in 1:n
		Class = levels(grps)[i]
		Grp = grps .== Class

		pp_indices = shuffle(findall((grps.==Grp) .& (ŷ.==1))) # predicted positive for iᵗʰ class
		pn_indices = shuffle(findall((grps.==Class) .& (ŷ.==0))) # predicted negative for iᵗʰ class

		# Note : arrays in julia start from 1
		p2n_indices = pp_indices[1:convert(Int, floor(length(pp_indices)*p2n[i]))]
		n2p_indices = pn_indices[1:convert(Int, floor(length(pn_indices)*n2p[i]))]

		ŷ[p2n_indices] = 1 .- ŷ[p2n_indices]
		ŷ[n2p_indices] = 1 .- ŷ[n2p_indices]
	end
	return ŷ
end
