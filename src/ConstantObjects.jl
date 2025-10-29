module ConstantObjects

using LinearAlgebra

"""
    Const{T}

    Wrapper type for marking any given object as constant/immutable.
"""
struct Const{T}
    _stored_object::T
end
export Const

"""
    MaybeConst{T}

    Helper union type to implement type-stable methods both for `T` and `Const{T}`
"""
const MaybeConst{T} = Union{T, Const{T}}
export MaybeConst


# make an argument const: bitstypes are already const by definition!
"""
    make_const(x::T) where {T}

    Wrap a given object in a constant/immutable `Const` wrapper.
    No wrapping is needed for objects whose type is `isbitstype`: this is already constant in the sense of this package.
"""
function make_const(x::T) where {T}
    return isbitstype(T) ? x : Const(x)
end
export make_const


"""
    remove_const(c::Const{T}) where {T}

    remove the `Const` wrapper from a stored object. Does nothing for non-`Const` types.
"""
remove_const(c::Const{T}) where {T} = c._stored_object
export remove_const

# forward property calls to the stored_object, but return the stored_object if explicitly requested
function Base.getproperty(c::Const{T}, s::Symbol) where {T}
    if s == :_stored_object
        return getfield(c, s)
    else
        return make_const(Base.getproperty(remove_const(c), s))
    end
end

## SETTER: DO NOT ALLOW MODIFICATIONS ##
Base.setproperty!(c::Const{T}, s::Symbol) where {T} = error("setproperty! is not allowed for a ConstantObject")
Base.setindex!(c::Const{T}, args...) where {T} = error("setindex! is not allowed for a ConstantObject")


## Base functions that we trust ##
for f in [
        :getindex,
        :iterate,
        :length,
        :size,
        # tbc...
    ]
    @eval Base.$f(c::Const{T}, args...) where {T} = make_const(Base.$f(remove_const(c), args...))
end

## LinearAlgebra functions that we trust ##
for f in [
        :det,
        :norm,
        # tbc...
    ]
    @eval LinearAlgebra.$f(c::Const{T}, args...) where {T} = make_const(LinearAlgebra.$f(remove_const(c), args...))
end

end # module ConstantObjects
