using WordTokenizers

export SpamFilter

spam_tokenise(s) = WordTokenizers.tokenize(lowercase(replace(s, "."=>"")))

function frequencies(xs)
  frequencies = Dict{eltype(xs),Int}()
  for x in xs
    frequencies[x] = get(frequencies, x, 0) + 1
  end
  return frequencies
end

function features(fs::AbstractDict, dict)
  bag = zeros(Int, size(dict))
  for i = 1:length(dict)
    bag[i] = get(fs, dict[i], 0)
  end
  return bag
end

features(s::AbstractString, dict) = features(frequencies(spam_tokenise(s)), dict)

Features{T<:Integer} = AbstractVector{T}

mutable struct SpamFilter{T}
  dict::Vector{String}
  classes::Vector{T}
  weights::Matrix{Int}
end

SpamFilter(dict, classes) =
  SpamFilter(dict, classes,
             ones(Int, length(dict), length(classes)))

SpamFilter(classes) = SpamFilter(String[], classes)

probabilities(c::SpamFilter) = c.weights ./ sum(c.weights, dims = 1)

function extend!(c::SpamFilter, class)
  push!(c.dict, class)
  c.weights = vcat(c.weights, ones(Int, length(c.classes))')
  return c
end

function fit!(c::SpamFilter, x::Features, class)
  n = findfirst(==(class), c.classes)
  c.weights[:, n] .+= x
  return c
end

function fit!(c::SpamFilter, s::String, class)
  fs = frequencies(spam_tokenise(s))
  for k in keys(fs)
    k in c.dict || extend!(c, k)
  end
  fit!(c, features(s, c.dict), class)
end

function predict(c::SpamFilter, x::Features)
  ps = prod(probabilities(c) .^ x, dims = 1)
  ps ./= sum(ps)
  Dict(c.classes[i] => ps[i] for i = 1:length(c.classes))
end

predict(c::SpamFilter, s::String) =
  predict(c, features(s, c.dict))
