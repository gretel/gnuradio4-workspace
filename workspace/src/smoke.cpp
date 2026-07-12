#include <cassert>
#include <cstdio>

#include <gnuradio-4.0/Block.hpp>
#include <gnuradio-4.0/BlockMerging.hpp>
#include <gnuradio-4.0/Port.hpp>

template<typename T>
struct Adder : public gr::Block<Adder<T>> {
    gr::PortIn<T>  in0;
    gr::PortIn<T>  in1;
    gr::PortOut<T> out;

    GR_MAKE_REFLECTABLE(Adder, in0, in1, out);

    template<gr::meta::t_or_simd<T> V>
    [[nodiscard]] constexpr auto processOne(V a, V b) const noexcept {
        return a + b;
    }
};

template<typename T, T ScaleFactor>
struct ScaleBlock : public gr::Block<ScaleBlock<T, ScaleFactor>> {
    gr::PortIn<T>  in;
    gr::PortOut<T> out;

    GR_MAKE_REFLECTABLE(ScaleBlock, in, out);

    template<gr::meta::t_or_simd<T> V>
    [[nodiscard]] constexpr auto processOne(V a) const noexcept {
        return a * ScaleFactor;
    }
};

int main() {
    using gr::MergeByIndex;

    // Adder -> Scale<*2>
    auto merged = MergeByIndex<Adder<int>, 0, ScaleBlock<int, 2>, 0>();
    int  r      = 0;
    for (int i = 0; i < 3; ++i) {
        r += merged.processOne(i, 10 - i);
    }
    // Each pair sums to 10, ScaleBlock expands to 20 → 3×20 = 60
    assert(r == 60);
    (void)r; // suppress unused-variable warning when NDEBUG defined
    std::printf("workspace smoke: OK\n");
    return 0;
}
