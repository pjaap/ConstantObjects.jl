using ConstantObjects
using Test
using LinearAlgebra

@testset "Arrays" begin

    A = zeros(10, 10)
    cA = make_const(A)

    @test size(cA) == size(A)
    @test A[3,3] == cA[3,3]
    @test det(A) == det(cA)
    @test sum(A) == sum(cA)

    @test_throws ErrorException cA[4,4] = 42
end


@testset "Dictionaries" begin

   d = Dict(
    :a => 1,
    "foo" => "bar"
   )

   dd = Dict(
    :d => d,
    :b => zeros(3)
   )

    cdd = make_const(dd)

    @test length(cdd) == length(dd)
    @test cdd[:d][:a] == d[:a]

    d2 = cdd[:d]
    @test_throws ErrorException d2[:c] = "fail, d2 is const"

end