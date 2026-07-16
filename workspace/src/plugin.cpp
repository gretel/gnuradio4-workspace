// SPDX-License-Identifier: MIT
// Minimal test plugin for workspace diagnostic binary

#include <gnuradio-4.0/Block.hpp>
#include <gnuradio-4.0/Plugin.hpp>

GR_PLUGIN("Workspace Test Plugin", "GNU Radio Contributors", "MIT", "v1")

namespace gr4_workspace {

struct TestBlock : public gr::Block<TestBlock> {
    gr::PortIn<float>  in;
    gr::PortOut<float> out;

    GR_MAKE_REFLECTABLE(TestBlock, in, out);

    [[nodiscard]] constexpr float processOne(float x) const noexcept { return x; }
};

} // namespace gr4_workspace

auto registerTestBlock = gr::registerBlock<gr4_workspace::TestBlock>(static_cast<gr::BlockRegistry&>(grPluginInstance()));
