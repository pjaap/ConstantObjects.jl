# ConstantObjects

[![Build Status](https://github.com/pjaap/ConstantObjects.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/pjaap/ConstantObjects.jl/actions/workflows/CI.yml?query=branch%3Amain)

A small package for those who need real __constant__ and __immutable__ objects in Julia.


> [!WARNING]
> This is a demo package with __very__ limited capabilities so far. Use just for testing.


## Motivation for creating this package

Refugees from C++ may miss one particular feature in Julia: An equivalent mechanism for securing arbitrary objects agains mutations.
```c++
    auto foo(const auto& bar)
    {
        bar.baz = 42 // ERROR
    }
```
In C++, this can be realized by _constant references_.

In Julia, the user has total freedom over the mutability of objects and Julia does not provide constant references.

Of course, Julia has __immutable structs__, and, by convention, functions without the bang `!` do not mutate the input.

However, the properties of an immutable struct may not be immutable:
```julia
    struct Foo
        a # a is "constant"
    end

    a = zero(10)
    foo = Foo(a)
    foo.a[3] = 4 # totally ok :(
```

And the bang `!` convention needs __trust__. Do you trust an external library? Do you trust yourself?

This problem is addressed by this package: We introduce `ConstantObjects`!

## Getting started

Add this package to your project and use it:
```
pkg> add https://github.com/pjaap/ConstantObjects.jl

julia> using ConstantObjects
```

### Creating constant objects

Any object can be made `constant` by the `make_const` function:
```julia
using LinearAlgebra

A = rand(10, 10)
cA = make_const(A)
det(A) == det(cA) # true
cA[1,1] = 42.0 # ERROR

d = Dict(:a => "hello", :b => "world")
dd = Dict(:d => d)
cdd = make_const(dd)
cdd[:d][:c] = "this will fail" # that's right, immutability applies also to all stored properties!
```

### Using `ConstantObjects` in your project

By testing the lines above, you have noticed that `make_const` changes the type of the object.
If you use type annotated methods, like
```julia
function foo(x::MyType, args...)
```
then you need to change the annotation to either
```julia
function foo(x::Const{MyType}, args...)
```
to use it with constant objects only, or
```julia
function foo(x::MaybeConst{MyType}, args...)
```
to use it with both constant and mutable objects.

The helper type `MaybeConst{T}` is just an alias for `Union{T, Const{T}}`.


## Trust

You will quickly find out that all of this will break down if type annotated external functions are called with constant objects.

To circumvent this, we __trust__ certain functions and hand over the stored mutable object.
In detail, we remove the constant layer with `remove_const`, call the function, and call `make_const` on the return value.

> [!NOTE]
> This is currently only implemented for Base functions like `getindex`, `iterate`, `size`. And for some `LinearAlgebra` functions like `det` and `norm`.
> An efficient mechnism to add a large chunks of trusted functions is needed.


## How does it work?

Pretty simple: We wrap an object by the wrapper type `Const`. We implement `setproperty!` and `setindex!` to error.
All `getproperty` calls are forwarded to the `_stored_object`, except the call for this object itself.
The return values of `getproperty` are passed through `make_const` be also constant.

Julia's own types which fulfill `isbitstype` are excluded from the `Const` wrapper in `make_const`, since those objects already have the desired properties [by design](https://docs.julialang.org/en/v1/base/base/#Base.isbitstype).

Hence, `make_const(42)` will simply return `42` and `make_const("mutable_string")` will add the `Const` type, since the string is mutable.

This makes "low level" data access in `Arrays` and other containers applicable to math operations.


## Open problems

- user facing way to add __trusted__ methods
- `Const{T}` loses all type relations of `T` (`supertypes`, `T <: SomeAbstractType`)

